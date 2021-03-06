use warnings;
use strict;
use Test::More;

use CUDA::DriverAPI;
use Cwd;
use File::Spec;

my $max = 10;
my $max_data  = pack('i', $max);
my $host_data = pack('f*', 1..$max);

my $path = File::Spec->catfile(cwd(), qw/ t ptx 01_simple.ptx /);

my $ctx = CUDA::DriverAPI->new();

my $dev_ptr_1 = $ctx->malloc($host_data);
my $dev_ptr_2 = $ctx->malloc($host_data);
my $dev_ptr_3 = $ctx->malloc($host_data);
my $int_ptr   = $ctx->malloc($max_data);

$ctx->transfer_h2d($host_data, $dev_ptr_1);
$ctx->transfer_h2d($host_data, $dev_ptr_2);
$ctx->transfer_h2d($max_data,  $int_ptr  );

subtest 'Run successfully' => sub {
    $ctx->run($path, 'kernel_sum', [
        $dev_ptr_1,
        $dev_ptr_2,
        $dev_ptr_3,
        $int_ptr,
    ], [
        $max
    ]
    );

    my $result = pack('f*', (0) x $max);
    $ctx->transfer_d2h($dev_ptr_3, \$result);

    my @results = unpack('f*', $result);

    is_deeply(\@results, [map { $_ * 2 } 1..$max]);
};

done_testing;

