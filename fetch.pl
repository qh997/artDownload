#!/usr/bin/perl
use warnings;
use strict;
use LWP;
use LWP::Simple;
use Encode qw(decode encode);

$SIG{INT} = \&get_out;

my $url = 'http://airenti.org/Html/Type/1_1.html';
my $url_girls = 'http://www.airenti.org/Html/';
my $local_path = '/cygdrive/d/Downloads/art/';
my $store_path = '/cygdrive/g/用户-User/Pictures/Pornography/art/';
my @store_path = (
    '/cygdrive/g/用户-User/Pictures/Pornography/art01/',
    '/cygdrive/g/用户-User/Pictures/Pornography/art02/',
    '/cygdrive/g/用户-User/Pictures/Pornography/art03/',
);
my $crt_file = '';
my $tmp_dir = '.art';
my $max_chd = 20;

my @HEAD = (
    'Host' => 'processbase.neusoft.com',
    'User-Agent' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:10.0.1) Gecko/20100101 Firefox/10.0.1',
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language' => 'en-us,en;q=0.5',
    'Accept-Encoding' => 'gzip, deflate',
    'Connection' => 'keep-alive',
);

my $browser = LWP::UserAgent->new();
my $next_url = $url;
do {
    my $response = $browser->get($next_url);
    my $index_page = $response->content;
    my $this_path = $next_url;

    $index_page = encode("gbk", decode("utf8", $index_page));
    $this_path =~ s/(.*\/).*/$1/;

    while ($index_page =~ m/<a\s+href="(.*?)".*?alt="(.*?)".*?\2/g) {
        my $girl_url = $1;
        my $title = $2;
        my $index = $girl_url;
        $index =~ s/.*\/(\d+)_.*/$1/;

        get_girl_pics($title, $this_path.$girl_url, $index);
    }

    my $crnt_url = $next_url;
    my $str_nextpage = encode("gbk", decode("utf8", "下一页"));
    if ($index_page =~ m/.*<a href="(.*?)">$str_nextpage<\/a>/) {
        $next_url = $1;
        if ($crnt_url ne $this_path.$next_url) {
            $next_url = $this_path.$next_url;
        }
    }
    else {
        $next_url = '';
    }
} while ($next_url);

sub get_girl_pics {
    my $title = shift;
    my $url = shift;
    my $index = shift;

    print $index.'-'.$title."\n";

    foreach (@store_path) {
        if (-d $_.$index.'-'.$title) {
            goto return;
        }
    }

    if (!-d $local_path.$index.'-'.$title) {
        my $girl_res = $browser->get($url);
        my $page_content = $girl_res->content;
        my $_page_content = $page_content;
        $page_content = encode("gbk", decode("utf8", $page_content));

        my $girl_no = $url;
        $girl_no =~ s/.*\/(\d+)_.*/$1/;

        my $pageindex = $url;
        $pageindex =~ s{/[^/]+$}{};

        if ($page_content =~ /<(title)>(.*?)<\/\1>/) {
            my @children;
            my $tmp_path = $local_path.$index.'-'.$title.$tmp_dir;
            -d $tmp_path or mkdir($tmp_path);

            get_girl_pic($_page_content, $title, \@children, $index);
            while ($page_content =~ m{.*?href="(${girl_no}_(\d+)\.html)">\2}g) {
                get_girl_pic($browser->get($pageindex.'/'.$1)->content, $title, \@children, $index);
            }

            foreach my $child (@children) {
                waitpid($child, 0);
            }
            rename($tmp_path, $local_path.$index.'-'.$title);
        }
    }
}

sub get_girl_pic {
    my $page = shift;
    my $title = shift;
    my $chd = shift;
    my $index = shift;

    $page = encode("gbk", decode("utf8", $page));

    while ($page =~ /<img\s+src="(.*?)"\s+alt="\Q${title}\E"/g) {
        my $pic_file = $1;
        $pic_file =~ s/^\s+//;
        $pic_file =~ s/\s+$//;
        my $local_file = $pic_file;

        $local_file =~ s/.*\///;
        $local_file = $local_path.$index.'-'.$title.$tmp_dir.'/'.$local_file;

        if (! -e $local_file) {
            if ($#$chd >= $max_chd - 1) {
                wait;
            }

            my $pid = fork;
            if ($pid) {
#                $chd_prc_no++;
                push @$chd, $pid;
            }
            elsif (defined $pid && $pid == 0) {
                # print "\t".$pic_file."\n";
                print "\t => .../$index-$title/", (split('/', $pic_file))[-1],"\n";
                $crt_file = $local_file;
                LWP::Simple::getstore($pic_file, $local_file);
                $crt_file = '';

                exit;
            }
        }
    }
}

sub get_out {
    if ($crt_file) {
        unlink ($crt_file);
    }
    exit;
}
