package Datahub::Factory::TMS::Import;

use Moo;
use Catmandu;
use strict;

use DBI;
use Log::Log4perl;
use Config::Simple;

use Data::Dumper qw(Dumper);

use Datahub::Factory::TMS::Import::Index;
use Datahub::Factory::Import::PIDS;

has db_host     => (is => 'ro', required => 1);
has db_name     => (is => 'ro', required => 1);
has db_user     => (is => 'ro', required => 1);
has db_password => (is => 'ro', required => 1);


has importer  => (is => 'lazy');
has logger    => (is => 'lazy');
has pids      => (is => 'lazy');
has config    => (is => 'lazy');

sub _build_logger {
    my $self = shift;
    return Log::Log4perl->get_logger('datahub');
}

sub _build_importer {
    my $self = shift;
    my $dsn = sprintf('dbi:mysql:%s', $self->db_name);
    my $query = 'select * from vgsrpObjTombstoneD_RO;';
    my $importer = Catmandu->importer('DBI', dsn => $dsn, host => $self->db_host, user => $self->db_user, password => $self->db_password, query => $query, encoding => ':iso-8859-1');
    #$self->prepare();
    return $importer;
}

sub _build_pids {
    my $self = shift;
    return Datahub::Factory::Import::PIDS->new(
        username => $self->config->param('PIDS.username'),
        api_key  => $self->config->param('PIDS.api_key')
    );
}

sub _build_config {
    my $self = shift;
    return new Config::Simple('conf/settings.ini');
}

sub prepare {
    my $self = shift;
    # Add indices
    $self->logger->info('Creating indices on TMS tables.');
    Datahub::Factory::TMS::Import::Index->new(
        db_host => $self->db_host,
        db_name => $self->db_name,
        db_user => $self->db_user,
        db_password => $self->db_password
    );
    # Create temporary tables
    $self->logger->info('Adding "classifications" temporary table.');
    $self->__classifications();
    $self->logger->info('Adding "periods" temporary table.');
    $self->__period();
    $self->logger->info('Adding "dimensions" temporary table.');
    $self->__dimensions();
    $self->logger->info('Adding "subjects" temporary table.');
    $self->__subjects();
    $self->logger->info('Creating "pids" temporary table.');
    $self->__pids();
    $self->logger->info('Creating "creators" temporary table.');
    $self->__creators();
}

sub prepare_call {
    my ($self, $import_query, $store_table) = @_;
    my $importer = Catmandu->importer(
        'DBI',
        dsn      => sprintf('dbi:mysql:%s', $self->db_name),
        host     => $self->db_host,
        user     => $self->db_user,
        password => $self->db_password,
        query    => $import_query
    );
    my $store = Catmandu->store(
        'DBI',
        data_source => sprintf('dbi:SQLite:/tmp/tms_import.%s.sqlite', $store_table),
    );
   $importer->each(sub {
            my $item = shift;
            my $bag = $store->bag();
            # first $bag->get($item->{'_id'})
            $bag->add($item);
        });
}

sub merge_call {
    my ($self, $query, $key, $out_name) = @_;
    my $importer = Catmandu->importer(
        'DBI',
        dsn      => sprintf('dbi:mysql:%s', $self->db_name),
        host     => $self->db_host,
        user     => $self->db_user,
        password => $self->db_password,
        query    => $query
    );
    my $merged = {};
    $importer->each(sub {
        my $item = shift;
        my $objectid = $item->{'objectid'};
        if (exists($merged->{$objectid})) {
            push @{$merged->{$objectid}->{$key}}, $item;
        } else {
            $merged->{$objectid} = {
                $key => [$item]
            };
        }
    });
    my $store = Catmandu->store(
        'DBI',
        data_source => sprintf('dbi:SQLite:/tmp/tms_import.%s.sqlite', $out_name),
    );
    while (my ($object_id, $data) = each %{$merged}) {
        $store->bag->add({
            '_id' => $object_id,
            $key => $data->{$key}
        });
    }
}

sub __classifications {
    my $self = shift;
    $self->prepare_call('select ClassificationID as _id, Classification as term from Classifications', 'classifications');
}

sub __period {
    my $self = shift;
    $self->prepare_call('select ObjectID as _id, Period as term from ObjContext', 'periods')
}

sub __dimensions {
    my $self = shift;
    my $query = "SELECT o.ObjectID as objectid, d.Dimension as dimension, t.DimensionType as type, e.Element as element, u.UnitName as unit
    FROM vgsrpObjTombstoneD_RO o
    LEFT JOIN
        DimItemElemXrefs x ON x.ID = o.ObjectID
    INNER JOIN
        Dimensions d ON d.DimItemElemXrefID = x.DimItemElemXrefID
    INNER JOIN
        DimensionUnits u ON u.UnitID = d.PrimaryUnitID
    INNER JOIN
        DimensionTypes t ON t.DimensionTypeID = d.DimensionTypeID
    INNER JOIN
        DimensionElements e ON e.ElementID = x.ElementID
    WHERE
        x.TableID = '108'
    AND 
        x.ElementID = '3';";
    $self->merge_call($query, 'dimensions', 'dimensions');
}

sub __subjects {
    my $self = shift;
    my $query = "SELECT o.ObjectID as objectid, t.Term as subject
    FROM Terms t, vgsrpObjTombstoneD_RO o, ThesXrefs x, ThesXrefTypes y
    WHERE
    x.TermID = t.TermID and
    x.ID = o.ObjectID and
    x.ThesXrefTypeID = y.ThesXrefTypeID and
    y.ThesXrefTypeID = 30;"; # Only those from the VKC website
    $self->merge_call($query, 'subjects', 'subjects');
}

sub __pids {
    my $self = shift;
    $self->pids->temporary_table($self->pids->get_object('PIDS_KMSKA_UTF8.csv'), 'export20131204 - ID');
}

sub __creators {
    my $self = shift;
    $self->pids->temporary_table($self->pids->get_object('CREATORS_KMSKA_UTF8.csv'));
}

1;