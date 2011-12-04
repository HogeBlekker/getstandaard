#!/usr/bin/env perl
# By HogeBlekker
use strict;
use warnings;
# To download files
use WWW::Mechanize;
# To parse forms
use HTML::Form;
# To handle PDFs
use CAM::PDF;
# To get commandline options
use Getopt::Std;
our($opt_D, $opt_v, $opt_b, $opt_o, $opt_s, $opt_e, $opt_u, $opt_i, $opt_c, $opt_p, $opt_W);

my $login = '';
my $password = '';

# Do not edit below this line
my @choices;

# Get commandline switches
getopts('Dvboseuicp');
if ($opt_D) { # Dagkrant
	if ($opt_v && $opt_b && $opt_o && $opt_s && $opt_e && $opt_u) { # && $opt_i && $opt_c && $opt_p) {
		unshift(@choices,"Dagkrant");
	} elsif (! defined $opt_v && ! defined $opt_b && ! defined $opt_o && ! defined $opt_s && ! defined $opt_e && ! defined $opt_u) {
		unshift(@choices,"Dagkrant");
	} else {
		if ($opt_v) {push(@choices,"Vooraan in de krant");} else {$opt_v = 0}; # Vooraan in de krant
		if ($opt_b) {push(@choices,"Binnenland en buitenland");} else {$opt_b = 0}; # Binnenland en buitenland
		if ($opt_o) {push(@choices,"Opinie & Analyse");} else {$opt_o = 0}; # Opinie & Analyse
		if ($opt_s) {push(@choices,"Sport");} else {$opt_s = 0}; # Sport
		if ($opt_e) {push(@choices,"Economie");} else {$opt_e = 0}; # Economie
		if ($opt_u) {push(@choices,"Beurs");} else {$opt_u = 0}; # Beurs
		#if ($opt_i) {push(@choices,"Seintjes");} else {$opt_i = 0}; # Seintjes
		#if ($opt_c) {push(@choices,"Cultuur & Media");} else {$opt_c = 0}; # Cultuur & Media
		#if ($opt_p) {push(@choices,"Regio");} else {$opt_p = 0}; # Regio
	}
};
#print @choices;

# Make the Mech object
my $mech = WWW::Mechanize->new();
# Client spoofing: necessary?
$mech->add_header( 'User-Agent' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; nl; rv:1.9.2.6) Gecko/20100625 Firefox/3.6.6' );
$mech->add_header( 'Host' => 'www.standaard.be' );
$mech->add_header( 'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' );
$mech->add_header( 'Accept-Language' => 'nl,en-us;q=0.7,en;q=0.3' );
$mech->add_header( 'Accept-Encoding' => 'UTF8' );
$mech->add_header( 'Accept-Charset' => 'utf-8;q=0.7,*;q=0.7' );
$mech->add_header( 'Keep-Alive' => '115' );
$mech->add_header( 'Connection' => 'keep-alive' );
$mech->add_header( 'Referer' => 'http://www.standaard.be/' );

sub login {
	my $url = "http://www.standaard.be/registratie/aanmelden.aspx";
	$mech->get( $url );
    my $form = $mech->form_id('aspnetForm');
    my $email = $form->value( 'ctl00$ContentPlaceHolder1$aanmeldBox$tbEmail',$login);
    my $password = $form->value( 'ctl00$ContentPlaceHolder1$aanmeldBox$tbPassword',$password);
    my $response = $mech->request($form->click( 'ctl00$ContentPlaceHolder1$aanmeldBox$btnLogin' ));
}

sub getoverview {
	my $url = "http://www.standaard.be/krant/beeld/";
	$mech->get( $url );
	my $content = $mech->response()->as_string;
	my @rawdata = split(/\n/,$content);
	return @rawdata;
}

sub getpagelinks {
	my @choices = @_;
	my @pages;
	my @rawdata = getoverview;
	my $i = 0;
	my @data;
	my @tempsplit;
	my @returnarray;
	foreach my $line (@rawdata) {
		if ($line =~ m/arPages/ && $line =~ m/NewsPage/) {
			# Do some further cleanup
			$line =~ s/<script language='javascript'>//g;
			$data[$i] = $line;
			$i++;
		}
	}
	$i = 0;
	foreach my $line (@data) {
		foreach my $pagetype (@choices) {
			if ($line =~ m/$pagetype/) {
				@tempsplit = split(', ',$line);
				$tempsplit[5] =~ s/'//g;
				$tempsplit[5] =~ s/\);//;
				$returnarray[$i] = $tempsplit[5];
				$i++;
			}
		}
	}
	return @returnarray;
}

sub download {
	my $i = 0;
	my $output;
	my $otherpdf;
	foreach (@_) {
		my $url = "http://www.standaard.be/krant/beeld/toonpdf.aspx?file=" . $_[$i];
		my $page = "page" . $i . ".pdf";
		my $temp = $mech->get( $url);
		$temp = $mech->content();
		if ($i == 0) {
			$output = CAM::PDF->new($temp);
		} else {
			$otherpdf = CAM::PDF->new($temp);
			$output->appendPDF($otherpdf);
		}
		$i++;
	}
	(my $day, my $month, my $year) = (localtime)[3,4,5];
	$month += 1;
	$year -= 100;
	if ($day < 10) { $day = "0$day"; }
	my $krantnaam = "standaard_" . $year . $month . $day . ".pdf";
	$output->cleansave();
	$output->output($krantnaam);
}

login;
download(getpagelinks(@choices));