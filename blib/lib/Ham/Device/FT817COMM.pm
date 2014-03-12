# This is the Yaesu FT-817 Command Library Module
# Written by Jordan Rubin 
# For use with the FT-817 Serial Interface
#
# $Id: FT817COMM.pm 313 2014-03-10 12:00:00Z JRUBIN $
#
# Copyright (C) 2014, Jordan Rubin
# jrubin@cpan.org 



package Ham::Device::FT817COMM;

use strict;
use 5.006;

=head1 NAME
Ham::Device::FT817COMM - Library to control the Yaesu FT817 Ham Radio
=head1 VERSION
Version 0.9.0_01
=cut
our $VERSION = '0.9.0_01';
=head1 SYNOPSIS
Creates an instance of the FT817 in an object oriented fashion and allows calls to the serial interface
$self->{'port'}->command(chr($data1).chr($data2).chr($data3).chr($data4).chr($command));
This allows for complete control of the rig through the sub routines
all done through the cat interface

        $output = $self->eepromDecode(00,57);


=head1 AUTHOR
Jordan Rubin, C<< <jrubin at cpan.org> >>

=head1 BUGS
Please report any bugs or feature requests to C<bug-ham-device-ft817comm at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ham-Device-FT817COMM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT
You can find documentation for this module with the perldoc command.
    perldoc Ham::Device::FT817COMM

You can also look for information at:

=over 4
=item * RT: CPAN's request tracker (report bugs here)
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ham-Device-FT817COMM>
=item * AnnoCPAN: Annotated CPAN documentation
L<http://annocpan.org/dist/Ham-Device-FT817COMM>
=item * CPAN Ratings
L<http://cpanratings.perl.org/d/Ham-Device-FT817COMM>
=item * Search CPAN
L<http://search.cpan.org/dist/Ham-Device-FT817COMM/>
=back

=head1 ACKNOWLEDGEMENTS
Thank you to Clint Turner KA7OEI for his research on the FT817 and discovering the mysteries of the EEprom
FT817 and Yaesu are a registered trademark of Vertex standard Inc.


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jordan Rubin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut






BEGIN {
	use Exporter ();
	use vars qw($OS_win $VERSION $debug $verbose $agreewithwarning $writeallow $syntaxerr 
		%SMETER %SMETERLIN %PMETER %AGCMODES %TXPWR %OPMODES $catoutput $output 
		$squelch $currentmode $out $vfo $home $tuneselect $nb $lock $txpow 
		$toggled $writestatus $testbyte $dsp $fasttuning);




my $ft817;
my $catoutput;
my $currentmode;
my $output;

our $syntaxerr = "SYNTAX ERROR, CHECK WITH VERBOSE('1')\n";

our %AGCMODES = (AUTO => '00', FAST => '01', SLOW => '10', OFF => '11');

our %TXPWR = (HIGH => '00', LOW3 => '01', LOW2 => '10', LOW1 => '11');

our %VFOBANDS = ('160m' => '0000', '75m' => '0001', '40m' => '0010', '30m' => '0011',
             '20m' => '0100', '17m' => '0101', '15m' => '0110', '12m' => '0111',
             '10m' => '1000', '6m' => '1001', 'FMBC' => '1010', 'AIR' => '1011',
             '2m' => '1100', '70cm' => '1101', 'PHAN' => '1110');

our %OPMODES =  (LSB => '00', USB => '01', CW => '02',
             CWR => '03', AM => '04', FM => '08',
             DIG => '0a', PKT => '0c', FMN => '88',
             WFM => '06');

our %SMETER = ('S0' => '0000', 'S1' => '0001', 'S2' => '0010', 'S3' => '0011',
             'S4' => '0100', 'S5' => '0101', 'S6' => '0110', 'S7' => '0111',
             'S8' => '1000', 'S9' => '1001', '10+' => '1010', '20+' => '1011',
             '30+' => '1100', '40+' => '1101', '50+' => '1110', '60+' => '1111');

our %SMETERLIN = ('0' => '0000', '1' => '0001', '2' => '0010', '3' => '0011',
             '4' => '0100', '5' => '0101', '6' => '0110', '7' => '0111',
             '8' => '1000', '9' => '1001', '10' => '1010', '11' => '1011',
             '12' => '1100', '13' => '1101', '14' => '1110', '15' => '1111');

our %PMETER = ('0' => '0000', '1' => '0001', '2' => '0010', '3' => '0011',
             '4' => '0100', '5' => '0101', '6' => '0110', '7' => '0111',
             '8' => '1000', '9' => '1001', '10' => '1010', '11' => '1011',
             '12' => '1100', '13' => '1101', '14' => '1110', '15' => '1111');


	$OS_win = ($^O eq "MSWin32") ? 1 : 0;
	if ($OS_win) {
		eval "use Win32::SerialPort";
		die "$@\n" if ($@);
     		     }
	else {
		eval "use Device::SerialPort";
		die "$@\n" if ($@);
             } 
    

}#END BEGIN

sub new {
	my($device,%options) = @_;
	my $ob = bless \%options, $device;
	if ($OS_win) {
		$ob->{'port'} = Win32::SerialPort->new ($options{'serialport'});
          	     }
	else {
		$ob->{'port'} = Device::SerialPort->new ($options{'serialport'},'true',$options{'lockfile'});
  	     }
	die "Can't open serial port $options{'serialport'}: $^E\n" unless (ref $ob->{'port'});
	$ob->{'port'}->baudrate(9600) unless ($options{'baud'});
	$ob->{'port'}->databits (8);
	$ob->{'port'}->baudrate ($options{'baud'});
	$ob->{'port'}->parity  ("none");
	$ob->{'port'}->stopbits (2);
	$ob->{'port'}->handshake("none");
	$ob->{'port'}->read_char_time(0);
	$ob->{'port'}->read_const_time(1000);
return $ob;
	}

#### Closes the port and deconstructs method

sub moduleVersion {
        my $self  = shift;
return $VERSION;
                  }


sub closePort {
	my $self  = shift;
	die "\nCan't close the port $self->{'serialport'}....\n" unless $self->{'port'}->close;
	warn "\nPort $self->{'serialport'} has been closed.\n\n";
undef $self;
              }

#### sets debugflag if a value exists
sub setDebug {
	my $self = shift;
	my $debugflag = shift;
	if($debugflag == '1') {our $debug = $debugflag;}
	if($debugflag == '0') {our $debug = undef;}
	if($debug){print "DEBUGGER IS ON\n";}
        if(!$debug){print "DEBUGGER IS OFF\n";}
return $debug;
             }

#### sets output of a set command
sub setVerbose {
	my $self = shift;
	my $verboseflag = shift;
	if($verboseflag == '1') {our $verbose = $verboseflag;}
        if($verboseflag == '2') {our $verbose = $verboseflag;}
	if($verboseflag == '0') {$verbose = undef;}
        if($verbose){print "VERBOSE IS ON - LEVEL($verbose)\n";}
	if(!$verbose){print "VERBOSE IS OFF\n";}
return $verbose;
               }

#### sets output of a set command
sub setWriteallow {
        my $self = shift;
        my $writeflag = shift;
        if($writeflag == '1') {our $writeallow = $writeflag;}
        if($writeflag == '0') {our $writeallow = undef;}
if ($writeallow){print "WRITING TO EEPROM ACTIVATED";}
if (!$writeallow){print "WRITING TO EEPROM DEACTIVATED";}
if (!$agreewithwarning and $writeallow){print "
\n*****NOTICE****** *****NOTICE****** *****NOTICE****** *****NOTICE****** *****NOTICE******
\nYou have enabled the option setWriteallow!!!!\n 
\tWhile the program does its best to ensure that data does not get corrupted, there is always 
the chance that an error can be written to or received by the radio.  This radio has no checksum
feature with regard to writing to the EEprom. The user of this program assumes all risk associated
with using this software.\n
\tIt is recommended that the software calibration settings be backed up to your computer in the event
that the radio needs to be reset to factory default.  You should have done this anyway, to avoid
sending the radio back to Yaesu to be recalibrated. Use software such as \'FT-817 commander\' to backup
your software calibration. check the site http://wb8nut.com/downloads/ or google it.  The program is
for windows but functions fine on Ubuntu linux and other possible variants under wine.\n
\tHaving said that, If you accept this risk and have backed up your software calibration, you can use
the following command agreewithwarning(1) before the command setWriteallow(1) in your software to get
rid of this message and have the ability to write to the eeprom.
";					}
	  
		 }
#### sets output of a set command
sub agreewithwarning {
        my $self = shift;
        my $agreeflag = shift;
        if($agreeflag == '1') {our $agreewithwarning = $agreeflag;}
return $agreewithwarning;
                     }

sub getFlags {
        my $self = shift;
my $flags = "DEBUG\:$debug \/ VERBOSE\:$verbose \/ WRITE ALLOW:$writeallow \/ WARNED\:$agreewithwarning";
return $flags;
             }
#### Convert a decimal to a binary
sub dec2bin {
	my $str = unpack("B32", pack("N", shift));
	$str = substr $str, -8;
return $str;
            }

#### Convert Hex to a binary
sub hex2bin {
	my $h = shift;
	my $hlen = length($h);
	my $blen = $hlen * 4;
return unpack("B$blen", pack("H$hlen", $h));
            }

#### Send a CAT command and set the return byte size
sub sendCat {
	my $self  = shift;
	my ($data1, $data2, $data3, $data4, $command, $outputsize) = @_;
	if ($debug){print "\nsendcat:debug - DATA OUT ----> $data1 $data2 $data3 $data4 $command\n";}
	$data1 = hex($data1);
	$data2 = hex($data2);
	$data3 = hex($data3);
	$data4 = hex($data4);
	$command = hex($command);
	$self->{'port'}->write(chr($data1).chr($data2).chr($data3).chr($data4).chr($command));
	$catoutput = $self->{'port'}->read($outputsize);
	$catoutput = unpack("H*", $catoutput);
	if ($debug) {print "sendcat:debug - DATA IN <----- $catoutput\n\n";}
return $catoutput;
            }

#### Decodes eeprom values from a given address and stips off second byte
sub eepromDecode {
	my $self  = shift;
	my ($MSB, $LSB) = @_;
	if ($debug){print "\neepromdecode:debug - Output from MSB:$MSB LSB:$LSB";}
	$MSB = hex($MSB);
	$LSB = hex($LSB);
	$self->{'port'}->write(chr($MSB).chr($LSB).chr(0).chr(0).chr(0xBB));
	$output = $self->{'port'}->read(2);
	$output = unpack("H*", substr($output,0,1));
	$output = hex2bin($output);
	if ($debug){print " : $output\n";}
return $output;
                 }


#### Writes data to the eeprom MSB,LSB,BIT# and VALUE,  REWRITES NEXT MEMORY ADDRESS
sub writeEeprom {
        my $self=shift;
	my ($MSB, $LSB, $BIT, $VALUE,$writestatus) = @_;
	my $MSB=shift;
	my $LSB=shift;
	my $BIT=shift;
	my $VALUE=shift;

	if ($writeallow != '1' and $agreewithwarning != '1') {
		if($debug || $verbose == '2'){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
		if ($verbose == '1'){ print "Writing to EEPROM disabled and must be enabled before use....\n";}
		$writestatus = "Write Disabled";
return $writestatus;
			  }
	if ($debug){print "\neepromdecode:debug - Output from MSB:$MSB LSB:$LSB\n";}
        my $addressname = $LSB;
	$MSB = hex($MSB);
	$LSB = hex($LSB);
	$self->{'port'}->write(chr($MSB).chr($LSB).chr(0).chr(0).chr(0xBB));
	my $output = $self->{'port'}->read(2);
	my $BYTE1 = unpack("H*", substr($output,0,1));
	my $BYTE2 = unpack("H*", substr($output,1,1));
	if ($debug){print "Byte1: ($BYTE1) Byte2: ($BYTE2) $MSB $LSB o:$output\n";}
	$BYTE1 = hex2bin($BYTE1);
	my $HEX1 = sprintf("%x", oct( "0b$BYTE1" ) );
	if ($debug){print "Byte1: binary is $BYTE1\n";}
	if ($debug){print "Changing bit $BIT to $VALUE\n\n";}
	substr($BYTE1, $BIT, 1) = "$VALUE";
	if ($debug){print "Byte1: $BYTE1 binary after change\n";}
	my $NEWHEX1 = sprintf("%x", oct( "0b$BYTE1" ) );
	if ($debug){print "Byte1: $NEWHEX1 HEX after change\n";}
	if ($debug){print "Values to be written are\nByte1: ($NEWHEX1) Byte2: ($BYTE2)\n";}
        my $oldbyte1 = $NEWHEX1;
        my $oldbyte2 = $BYTE2;
	$NEWHEX1 = hex($NEWHEX1);
	my $NEWHEX2 = hex($BYTE2);
	if ($debug){print "Numeric values Byte1: ($NEWHEX1) Byte2: ($NEWHEX2)\n";}
	$self->{'port'}->write(chr($MSB).chr($LSB).chr($NEWHEX1).chr($NEWHEX2).chr(0xBC));
	if ($debug){print "New values written. checking them...\n\n";}
        $self->{'port'}->write(chr($MSB).chr($LSB).chr(0).chr(0).chr(0xBB));
        my $output2 = $self->{'port'}->read(2);
        if ($debug){print "Should be: ($oldbyte1) ($oldbyte2)\n\n";}
	if ($output2 == $output) {
		$writestatus = "OK";
		if($debug){print "Values match\n";}}
        else {
		$writestatus = "ERROR, Run restoreEeprom($addressname) to return memory area to default";
		if($debug){print "Values did not match\n";}}
return $writestatus;
}

#### Restores eprom memory address to pre written default value in case there was an error
# Currently supports address (5f)
sub restoreEeprom {
        my $self=shift;
        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose == '2'){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
                if ($verbose == '1'){ print "Writing to EEPROM disabled and must be enabled before use....\n";}
                $writestatus = "Write Disabled";
return $writestatus;
                          }
        my ($area,$MSB,$LSB,$writestatus,$testbyte1,$testbyte2) = @_;
	if ($area ne '5f'){
		if($debug || $verbose){print "Address ($area) not supported for restore...\n";}
		$writestatus = "Invalid memory address ($area)";
return $writestatus;
			  }

	if ($area eq '5f'){
		$self->{'port'}->write(chr(0).chr(95).chr(101).chr(25).chr(0xBC));
		$MSB = hex('00');
	       	$LSB = hex('5f');
			  }
	if($debug){print "Rewrote default memory values to 0x$area\n";}
	$self->{'port'}->write(chr($MSB).chr($LSB).chr(0).chr(0).chr(0xBB));
	my $output = $self->{'port'}->read(2);
	if($debug){print "Checking new value in 0x$area\n";}
	if ($area eq '5f'){$testbyte = 'e';} 
	if ($testbyte eq 'e') {
	        $writestatus = "OK";
	       	if($debug){print "Restore area $area sucessfull!\n";}
		if($verbose){print "Restore of (65) (19) to 0x$area sucessfull!\n";}
							       }
	else {
		$writestatus = "ERROR, Run restoreEeprom(\'$area\') to return memory area to default";
	    	if($debug){print "Restore failed!\n";}
		if($verbose){print "Restore of (65) (19) to 0x$area failed!\n";}
             }
return $writestatus;
		  }

###############################
#CAT COMMANDS IN ORDER BY BOOK#
###############################



#### ENABLE/DISABLE LOCK VIA CAT
sub setLock {
	my ($lock,$data) = @_;
	my $self=shift;
	my $lock = shift;
        $data = undef;
	if ($lock eq 'enable') {$data = "0x00";}
	if ($lock eq 'disable') {$data = "0x80";}
	if ($data){$catoutput = $self->sendCat('00','00','00','00',"$data",1);}
	else {$catoutput = "$syntaxerr";}
	if ($verbose){
                print "Set Lock ($lock) Failed. Option:$lock invalid.\n" if (! $data);
		print "Set Lock ($lock) Sucessfull.\n" if ($catoutput eq '00');
		print "Set Lock ($lock) Failed. Already set to $lock\?\n" if ($catoutput eq 'f0');
           	     }
return $catoutput;
            }

#### ENABLE/DISABLE PTT VIA CAT
sub setPtt {
	my ($ptt,$data) = @_;
	my $self=shift;
	my $ptt = shift;
	$data = undef;
	if ($ptt eq 'enable') {$data = "0x08";}
	if ($ptt eq 'disable') {$data = "0x88";}
	if ($data){$catoutput = $self->sendCat('00','00','00','00',"$data",1);}
	else {$catoutput = "$syntaxerr";}
	if ($verbose){
                print "Set PTT ($ptt) Failed. Option:$ptt invalid.\n" if (! $data);
		print "Set PTT ($ptt) Sucessfull.\n" if ($catoutput eq '00');
		print "Set PTT ($ptt) Failed. Already set to $ptt\?\n" if ($catoutput eq 'f0');
            	     }
return $catoutput;
           }

#### SET CURRENT FREQ USING CAT
sub setFrequency {
	my ($newfrequency,$badf,$f1,$f2,$f3,$f4) = @_;
	my $self=shift;
	my $newfrequency = shift;

        if ($newfrequency!~ /\D/ && length($newfrequency)=='8') {
		$f1 = substr($newfrequency, 0,2);
		$f2 = substr($newfrequency, 2,2);
		$f3 = substr($newfrequency, 4,2);
		$f4 = substr($newfrequency, 6,2);
							        }
	else {
		$badf = $newfrequency;
		$newfrequency = undef;
                $catoutput = "$syntaxerr";
	     }
	if ($newfrequency){$catoutput = $self->sendCat("$f1","$f2","$f3","$f4",'0x01',1);}
	if ($verbose){
		print "Set Frequency ($badf) Failed. Must contain 8 digits 0-9.\n" if (! $newfrequency);
		print "Set Frequency ($newfrequency) Sucessfull.\n" if ($catoutput eq '00');
		print "Set Frequency ($newfrequency) Failed. $newfrequency invalid or out of range\?\n" if ($catoutput eq 'f0');
            	     }
return $catoutput;
                 }

#### SET MODE VIA CAT
sub setMode {
	my ($newmode) = @_;
	my $self=shift;
	my $newmode = shift;
	my %newhash = reverse %OPMODES;
	my ($mode) = grep { $newhash{$_} eq $newmode } keys %newhash;
	if ($mode){$catoutput = $self->sendCat("$mode","00","00","00",'0x07',1);}
	else {$catoutput = "$syntaxerr";}
	if ($verbose){
		print "Set Mode ($newmode) Sucessfull.\n" if ($catoutput eq '00');
		print "Set Mode ($newmode) Failed. $newmode is not valid mode\?\n" if (! $mode || $catoutput ne '00');
            	     }
return $catoutput;
         }

#### ENABLE/DISABLE CLARIFIER VIA CAT
sub setClarifier {
	my ($clarifier,$data) = @_;
	my $self=shift;
	my $clarifier = shift;
	$data = undef;
	if ($clarifier eq 'enable') {$data = "0x05";}
	if ($clarifier eq 'disable') {$data = "0x85";}
        if ($data){$catoutput = $self->sendCat('00','00','00','00',"$data",1);}
	else {$catoutput = "$syntaxerr";}
        if ($verbose){
                print "Set Clarifier ($clarifier) Failed. Option:$clarifier invalid.\n" if (! $data);
                print "Set Clarifier ($clarifier) Sucessfull.\n" if ($catoutput eq '00');
                print "Set Clarifier ($clarifier) Failed. Already set to $clarifier\?\n" if ($catoutput eq 'f0');
                     }
return $catoutput;
                 }

#### SET CLARIFIER FREQ AND POLARITY USING CAT
sub setClarifierfreq {
	my ($polarity,$frequency,$badf,$f1,$f2,$p) = @_;
	my $self=shift;
	my $polarity = shift;
	my $frequency = shift;
	$p = undef;
	$badf = undef;
	if ($frequency!~ /\D/ && length($frequency)=='4') {
                         $f1 = substr($frequency, 0,2);
                         $f2 = substr($frequency, 2,2);
							  }
		else {
			$badf = $frequency;
			$frequency = undef;
		     }  
	if ($polarity eq 'POS') {$p = '00';}
	if ($polarity eq 'NEG') {$p = '11';}
	if($frequency){if($p){
			$catoutput = $self->sendCat("$p",'00',"$f1","$f2",'0xf5',1)}};
	if($badf || !$p){$catoutput = "$syntaxerr";}
        if ($verbose){
                print "Set Clarifier Frequency ($polarity:$badf) Failed. Must contain 4 digits 0-9.\n" if (! $frequency);
		print "Set Clarifier Frequency ($polarity:$frequency) Failed. Option:$polarity invalid.\n" if (! $p);
		print "Set Clarifier Frequency ($polarity:$frequency) Sucessfull.\n" if ($catoutput eq '00');
		print "Set Clarifier Frequency ($polarity:$frequency) Failed. $frequency out of range\?\n" if ($catoutput eq 'f0');
                     }
return $catoutput;
                     }

#### TOGGLE VFO A/B VIA CAT
sub vfoToggle {
	my $self=shift;
	$catoutput = $self->sendCat('00','00','00','00','0x81',1);
        if ($verbose){
                print "VFO toggle Sucessfull.\n" if ($catoutput eq '00');
                print "VFO toggle Failed\n" if ($catoutput eq 'f0');
                     }
return $catoutput;
              }

#### ENABLE/DISABLE SPLIT FREQUENCY VIA CAT
sub setSplitfreq {
	my ($split,$data) = @_;
	my $self=shift;
	my $split = shift;
	$data = undef;
	if ($split eq 'enable') {$data = "0x02";}
	if ($split eq 'disable') {$data = "0x82";}
	if($data){$catoutput = $self->sendCat('00','00','00','00',"$data",1);}
	else{$catoutput = "$syntaxerr";}
        if ($verbose){
		print "Set Split Frequency ($split) Failed. Option:$split invalid.\n" if (! $data);
                print "Set Split Frequency ($split) Sucessfull.\n" if ($catoutput eq '00');
                print "Set Split Frequency ($split) Failed. Already set to $split\?\n" if ($catoutput eq 'f0');
                     }
return $catoutput;
              }

#### POS/NEG/SIMPLEX REPEATER OFFSET MODE VIA CAT
sub setOffsetmode {
	my ($offsetmode,$datablock) = @_;
	my $self=shift;
	my $offsetmode = shift;
	$datablock = undef;
	if ($offsetmode eq 'POS'){$datablock = '49';}
	if ($offsetmode eq 'NEG') {$datablock = '09';}
	if ($offsetmode eq 'SIMPLEX') {$datablock = '89';}
	if ($datablock){$catoutput = $self->sendCat("$datablock",'00','00','00','0x09',1);}
	else {$catoutput = "$syntaxerr";}
        if ($verbose){
                print "Set Offset Mode ($offsetmode) Sucessfull.\n" if ($datablock);
                print "Set Offset Mode ($offsetmode) Failed. Option:$offsetmode invalid\.\n" if (! $datablock);
                     }
return $catoutput;
                }

#### SET REPEATER OFFSET FREQ USING CAT
sub setOffsetfreq {
	my ($frequency,$badf,$f1,$f2,$f3,$f4) = @_;
        my $self=shift;
        my $frequency = shift;
        if ($frequency!~ /\D/ && length($frequency)=='8') {
		$f1 = substr($frequency, 0,2);
		$f2 = substr($frequency, 2,2);
		$f3 = substr($frequency, 4,2);
		$f4 = substr($frequency, 6,2);
							  }
        else {
                $badf = $frequency;
                $frequency = undef;
                $catoutput = "$syntaxerr";
             }
	if($frequency){$catoutput = $self->sendCat("$f1","$f2","$f3","$f4",'0xf9',1);}
        if($verbose){
                print "Set Offset Frequency ($badf) Failed. Must contain 8 digits 0-9.\n" if (! $frequency);
                print "Set Offset Frequency ($frequency) Sucessfull.\n" if ($catoutput eq '00');
                print "Set Offset Frequency ($frequency) Failed. $frequency invalid or out of range\?\n" if ($catoutput eq 'f0');
                    }
return $catoutput;
                 }

#### SETS CTCSS/DCS MODE VIA CAT
sub setCtcssdcs {
	my ($split,$data) = @_;
        my $self=shift;
        my $ctcssdcs = shift;
	$data = undef;
	if ($ctcssdcs eq 'DCS'){$data = "0a";}
	if ($ctcssdcs eq 'CTCSS'){$data = "2a";}
	if ($ctcssdcs eq 'ENCODER'){$data = "4a";}
	if ($ctcssdcs eq 'OFF'){$data = "8a";}
        if ($data){$catoutput = $self->sendCat("$data",'00','00','00','0x0a',1);}
	else {$catoutput = "$syntaxerr";}
        if ($verbose){
                print "Set Encoder Type ($ctcssdcs) Sucessfull.\n" if ($data);
                print "Set Encoder Type ($ctcssdcs) Failed. Option:$ctcssdcs invalid\.\n" if (! $data);
                     }
return $catoutput;
                }

#### SETS CTCSS TONE FREQUENCY
sub setCtcsstone {
	my ($tonefreq,$badf,$f1,$f2) = @_;
	my $self=shift;
	my $tonefreq = shift;
        if ($tonefreq!~ /\D/ && length($tonefreq)=='4') {
		$f1 = substr($tonefreq, 0,2);
		$f2 = substr($tonefreq, 2,2);
							}
	 else {
		$badf = $tonefreq;
		$tonefreq = undef;
                $catoutput = "$syntaxerr";
	      }
	if($tonefreq){$catoutput = $self->sendCat("$f1","$f2",'00','00','0x0b',1);}
        if ($verbose){
                print "Set CTCSS Tone ($badf) Failed. Must contain 4 digits 0-9.\n" if (! $tonefreq);
                print "Set CTCSS Tone ($tonefreq) Sucessfull.\n" if ($catoutput eq '00');
                print "Set CTCSS ($tonefreq) Failed. $tonefreq is not a valid tone frequency\.\n" if ($catoutput eq 'f0');
                     }
return $catoutput;
                 }

#### SET DCS CODE USING CAT######
sub setDcscode {
	my ($code,$badf,$f1,$f2) = @_;
        my $self=shift;
        my $code = shift;
        if ($code!~ /\D/ && length($code)=='4') {
		$f1 = substr($code, 0,2);
		$f2 = substr($code, 2,2);
						}
         else {
                $badf = $code;
                $code = undef;
		$catoutput = "$syntaxerr";
              }
	if($code){$catoutput = $self->sendCat("$f1","$f2",'00','00','0x0c',1);}
        if ($verbose){
                print "Set DCS Code ($badf) Failed. Must contain 4 digits 0-9.\n" if (! $code);
                print "Set DCS Code ($code) Sucessfull.\n" if ($catoutput eq '00');
                print "Set DCS Code ($code) Failed. $code is not a valid DCS Code\.\n" if ($catoutput eq 'f0');
                     }
return $catoutput;
                 }

#### GET MULTIPLE VALUES OF RX STATUS RETURN AS variables OR hash
sub getRxstatus {
        my ($option,$match,$desc) = @_;
        my $self=shift;
        my $option = shift;
	if (!$option){$option = 'hash';} 
        $catoutput = $self->sendCat('00','00','00','00','0xe7',1);
	my $values = hex2bin($catoutput);
	my $sq = substr($values,0,1);
	my $smeter = substr($values,4,4);
	my $smeterlin = substr($values,4,4);
	my $ctcssmatch = substr($values,2,1);
	my $descriminator = substr($values,3,1);
	($smeter) = grep { $SMETER{$_} eq $smeter } keys %SMETER;
	($smeterlin) = grep { $SMETERLIN{$_} eq $smeterlin } keys %SMETERLIN;
	if ($sq == 0) {$squelch = 'OFF';}
	if ($sq == 1) {$squelch = 'ON';}
	if ($ctcssmatch == 0) {$match = 'MATCHED/OFF';}
	if ($ctcssmatch == 1) {$match = 'UNMATCHED';}
	if ($descriminator == 0) {$desc = 'CENTERED';}
	if ($descriminator == 1) {$desc = 'OFF-CENTER';}
	if ($verbose) {
		print "Receive Status:\nSquelch: $squelch\nS-Meter: $smeter /$smeterlin\nTonematch: $match\nDescriminator: $desc\n";
		      }
	if ($option eq'variables'){
return ("$squelch","$smeter","$smeterlin" ,"$match", "$desc");
				  }
        if ($option eq 'hash') {
		my %rxstatus = ('squelch' => "$squelch", 'smeterdb' => "$smeter", 'smeterlinear' => "$smeterlin",
		'descriminator' => "$desc", 'ctcssmatch' => "$match");
return %rxstatus;
                               }
		}

#### GET MULTIPLE VALUES OF TX STATUS RETURN AS variables OR hash
sub getTxstatus {
        my ($option,$match,$desc,$ptt,$highswr,$split) = @_;
        my $self=shift;
        my $option = shift;
        if (!$option){$option = 'hash';}
        $catoutput = $self->sendCat('00','00','00','00','0xf7',1);
        my $values = hex2bin($catoutput);
        my $pttvalue = substr($values,0,1);
        my $pometer = substr($values,4,4);
        my $pometerlin = substr($values,4,4);
        my $highswrvalue = substr($values,2,1);
        my $splitvalue = substr($values,3,1);
        ($pometer) = grep { $PMETER{$_} eq $pometer } keys %PMETER;
        if ($pttvalue == 0) {$ptt = 'OFF';}
        if ($pttvalue == 1) {$ptt = 'ON';}
        if ($highswrvalue == 0) {$highswr = 'OFF';}
        if ($highswrvalue == 1) {$highswr = 'ON';}
        if ($splitvalue == 0) {$split = 'ON';}
        if ($splitvalue == 1) {$split = 'OFF';}
        if ($verbose) {
                print "Transmit Status:\nPower Meter: $pometer\nPTT: $ptt\nHigh SWR: $highswr\nSplit: $split\n";
                      }
        if ($option eq'variables'){
return ("$ptt","$pometer","$highswr" ,"$split");
                                  }
        if ($option eq 'hash') {
                my %txstatus = ('ptt' => "$ptt", 'pometer' => "$pometer",
                'highswr' => "$highswr", 'split' => "$split");
return %txstatus;
                               }
                  }

#### GET CURRENT FREQ USING CAT######
sub getFrequency {
	my ($freq, $formatted) = @_;
	my $self=shift;
	my $formatted = shift;
	$catoutput = $self->sendCat('00','00','00','00','0x03',5);
	$freq = substr($catoutput,0,8);
	$freq =~ s/^0+//;
	if ($formatted == 1)    {
		substr($freq,-2,0) = '.';
		substr($freq,-6,0) = '.';
		$freq .= " MHZ";
				}

        if ($verbose){
                print "Frequency is $freq\n";
                     }
return $freq;
                 }

#### GET CURRENT MODE USING CAT######
sub getMode {
	my $self=shift;
	my $formatted = shift;
	$catoutput = $self->sendCat('00','00','00','00','0x03',5);
	$currentmode = substr($catoutput,8,2);
	my ($mode) = grep { $OPMODES{$_} eq $currentmode } keys %OPMODES;
        if ($verbose){
                print "Mode is $mode\n";
                     }
return $catoutput;
            }

#### SETS RADIO POWER ON OR OFF VIA CAT
sub setPower {
	my ($powerset,$data) = @_;
	my $self=shift;
	my $powerset = shift;
	$data = undef;
	if ($powerset eq 'ON'){$data = "0x0f";}
	if ($powerset eq 'OFF') {$data = "0x8f";}
	if($data) {
		$self->sendCat('00','00','00','00','00',1);
		$catoutput = $self->sendCat('00','00','00','00',"$data",1);
		  }
	else {$catoutput = "$syntaxerr";}
	if($verbose){
                print "Set Power ($powerset) Sucessfull.\n" if ($catoutput eq '00');
                print "Set Power ($powerset) Failed. Already $powerset\?\n" if (!$catoutput);
		    }

return $catoutput;
	     }

###############################
#     END OF CAT COMMANDS     #
###############################






################################
# READ VALUES FROM EEPROM ADDR #
################################

# X ################################# GET VALUES OF EEPROM ADDRESS VIA EEPROMDECODE
###################################### READ ADDRESS GIVEN
sub getEeprom {
        my ($address,$address2) = @_;
        my $self=shift;
	my $address =shift;
	my $address2 = shift;


        if ($verbose){
                print "Get EEPROM ($address) Failed. Must contain  hex value 0-9 a-f.\n"; return 1 if (! $address);
                     }

               print "\n";
                printf "%-11s %-15s %-11s %-11s\n", 'ADDRESS', 'BINARY', 'DECIMAL', 'VALUE';
                print "___________________________________________________\n";
		my $valuebin = $self->eepromDecode(00,"$address");
                my $valuehex = sprintf("%x", oct( "0b$valuebin" ) );
                my $valuedec = hex($valuehex);
                printf "%-11s %-15s %-11s %-11s\n", "$address", "$valuebin", "$valuedec", "$valuehex";
		print "\n";
return $address;
              }


# 4-5 ################################# GET RADIO VERSION VIA EEPROMDECODE
###################################### READ ADDRESS 0X4 AND 0X5
sub getConfig {
        my ($type,$confighex4,$confighex5,$output4,$output5) = @_;
        my $self=shift;
	my $type=shift;
        $output4 = $self->eepromDecode(00,04);
	$confighex4 = sprintf("%x", oct( "0b$output4" ) );
        $output5 = $self->eepromDecode(00,05);
        $confighex5 = sprintf("%x", oct( "0b$output5" ) );
        $out = "\nHardware Jumpers created value of\n0x04[$output4]($confighex4)\n0x05[$output5]($confighex5)\n\n";
        if($verbose){
                print "$out";
	            }
return $out;
           }


# 7-53 ################################ GET SOFTWARE CAL VALUES EEPROMDECODE
###################################### READ ADDRESS 0X4 AND 0X5

sub getSoftcal {
        my $self=shift;
	my $option=shift;
	my $filename=shift;
	my $localtime = localtime();
	my $buildfile;
	if (!$option){$option = 'console';}
	my $block = 1;
	my $startaddress = '7';
	if ($option eq 'console' || $verbose){
		print "\n";
		printf "%-11s %-15s %-11s %-11s\n", 'ADDRESS', 'BINARY', 'DECIMAL', 'VALUE';
		print "___________________________________________________\n";
				 }

        if ($option eq 'file'){
		if (!$filename) {print"\nFilename required.     eg. /home/user/softcal.txt\n";return 0;}
		if (-e $filename) {
			print "\nFile exists. Backup/rename old file before creating new one.\n";
			return 0;
				  }
		else {
			$buildfile = '1';
			print "\nCreating calibration backup to $filename........\n";
			open  $filename, ">>", "$filename" or print"Can't open $filename. error\n";
			print $filename "FT817 Software Calibration Backup\nUsing FT817COMM.pm version $VERSION\n";
			print $filename "Created $localtime\n\n";
			printf $filename "%-11s %-15s %-11s %-11s\n", 'ADDRESS', 'BINARY', 'DECIMAL', 'VALUE';
                	print $filename "___________________________________________________\n";
		     }
                              }

	do {
		my $memoryaddress = sprintf("0x%x",$startaddress);
		my $valuebin = $self->eepromDecode(00,"$memoryaddress");
		my $valuehex = sprintf("%x", oct( "0b$valuebin" ) );
		my $valuedec = hex($valuehex);
	if ($option eq 'console' || $verbose) {
		printf "%-11s %-15s %-11s %-11s\n", "$memoryaddress", "$valuebin", "$valuedec", "$valuehex";
				  }
	if ($buildfile == '1'){
               printf $filename "%-11s %-15s %-11s %-11s\n", "$memoryaddress", "$valuebin", "$valuedec", "$valuehex";
			      }

		$block++;
		$startaddress ++;
	   }
	while ($block < '77');

        if ($buildfile == '1'){
                print $filename "\n\n---END OF Software Calibration Settings---\n";
                close $filename;
		return 0;
                              }
return $output;
                }


# 55 ################################# GET VFO A/B , HOME VFO OR MEMORY  VIA EEPROMDECODE
###################################### READ BIT 0 4 AND 8 FROM ADDRESS 0X55
sub getVfo {
	my $self=shift;
	$output = $self->eepromDecode(00,55);
	my @block55 = split("",$output);
	if ($block55[7] == '0') {$vfo = "A";}
	if ($block55[7] == '1') {$vfo = "B";}
        if($verbose == '1'){
                print "VFO is $vfo\n";
                           }
        if($verbose == '2'){
                print "getVfo: bit is ($block55[7]) VFO is $vfo\n";
                           }
return $vfo;
           }

sub getHome {
        my $self=shift;
        $output = $self->eepromDecode(00,55);
	my @block55 = split("",$output);
	if ($block55[3] == '1') {$home = "Y";}
	if ($block55[3] == '0') {$home = "N";}
        if($verbose == '1'){
		if($home eq'Y'){print "At Home Frequency.";}
		if($home eq 'N'){print "Not at Home Frequency";}
                           }
        if($verbose == '2'){
                print "getHome: bit is ($block55[3]) HOME is $home\n";
                           }
return $home;
            }

sub getTuner {
	my $self=shift;
	$output = $self->eepromDecode(00,55);
	my @block55 = split("",$output);
	if ($block55[0] == '0') {$tuneselect = "VFO";}
	if ($block55[0] == '1') {$tuneselect = "MEMORY";}
        if($verbose == '1'){
                print "Tuner is $tuneselect\n";
                           }
        if($verbose == '2'){
                print "getTuner: bit is ($block55[0]) TUNER is $tuneselect\n";
                           }
return $tuneselect;
             }

# 57 ################################# GET AGC MODE, NOISE BLOCK, DSP AND LOCK ######
###################################### READ BITS 0-1 , 2, 5 AND 6 FROM 0X57

sub getAgc {
	my $self=shift;
	$output = $self->eepromDecode(00,57);
	my $agcvalue = substr($output,6,2);
	my ($agc) = grep { $AGCMODES{$_} eq $agcvalue } keys %AGCMODES;
        if($verbose == '1'){
                print "AGC is $agc\n";
                           }
        if($verbose == '2'){
                print "getAgc: bits are ($agcvalue) AGC is $agc\n";
                           }
return $agc;
           }


sub getDsp {
        my $self=shift;
        $output = $self->eepromDecode(00,57);
        my @block55 = split("",$output);
        if ($block55[5] == '0') {$dsp = "OFF";}
        if ($block55[5] == '1') {$dsp = "ON";}
        if($verbose){
                print "getDsp: bit is ($block55[5]) DSP is $dsp\n";
                    }
return $dsp;
           }


sub getNb    {
	my $self=shift;
	$output = $self->eepromDecode(00,57);
	my @block55 = split("",$output);
	if ($block55[2] == '0') {$nb = "OFF";}
	if ($block55[2] == '1') {$nb = "ON";}
        if($verbose == '1'){
                print "Noise Blocker is $nb\n";
                           }
        if($verbose == '2'){
                print "getNb: bit is ($block55[2]) Noise Blocker is $nb\n";
                           }
return $nb;
             }

sub getLock    {
	my $self=shift;
	$output = $self->eepromDecode(00,57);
	my @block55 = split("",$output);
	if ($block55[1] == '1') {$lock = "OFF";}
	if ($block55[1] == '0') {$lock = "ON";}
        if($verbose == '1'){
                print "Lock is $lock\n";
                           }
        if($verbose == '2'){
                print "getLock: bit is ($block55[1]) Lock is $lock\n";
                           }
return $lock;
                }

sub getFasttuning {
        my $self=shift;
        $output = $self->eepromDecode(00,57);
        my @block55 = split("",$output);
        if ($block55[0] == '0') {$fasttuning = "OFF";}
        if ($block55[0] == '1') {$fasttuning = "ON";}
        if($verbose == '1'){
                print "Fast Tuning  is $fasttuning\n";
                           }
        if($verbose == '2'){
                print "getFasttuning: bit is ($block55[0]) Fast Tuning  is $fasttuning\n";
                           }
return $fasttuning;
           }



# 5f ################################# GET RFGAIN/SQUELCF ######
###################################### READ BIT 0-1 FROM 0X5f

sub getRfgain {
        my ($sqlbit,$value) = @_;
	my $self=shift;
        $output = $self->eepromDecode(00,'5f');
	$sqlbit = substr($output,0,1);
        if($sqlbit == '0'){$value = 'RFGAIN';}
        else {$value = 'SQUELCH';}
        if($verbose == '1'){
                print "RFGAIN Knob is set to $value\n";
                           }
        if($verbose == '2'){
                print "getRfgain: bit is ($sqlbit) RFGAIN Knob is $value\n";
                           }
return $value; 
           }


# 79 ################################# GET TX POWER ######
###################################### READ BIT 0-1 FROM 0X79

sub getTxpower {
	my $self=shift;
	$output = $self->eepromDecode(00,79);
	my $txpower = substr($output,6,2);
	($txpow) = grep { $TXPWR{$_} eq $txpower } keys %TXPWR;
        if($verbose == '1'){
                print "Tx power is $txpow\n";
                           }
        if($verbose == '2'){
                print "getTxpower: bits are ($txpower) Tx power is $txpow\n";
                           }
return $txpow;
               }





#################################
# WRITE VALUES FROM EEPROM ADDR #
#################################



# 5f ################################# TOGGLES RFGAIN/SQUENCH BIT
###################################### TOGGLE BIT 0 FROM ADDRESS 0X5F

sub toggleRfgain {
        my ($sqlbit, $writestatus,$value) = @_;
        my $self=shift;
        $output = $self->eepromDecode(00,'5f');
	$sqlbit = substr($output,0,1);
	if($sqlbit == '0'){$value = 'RFGAIN'}
	else {$value = 'SQUELCH'}
	if($debug){print "Currently set at $value , value ($sqlbit) at bit 0 of 0x5f\n";}
        if($sqlbit == 1){
	if($debug){print "Writing 0 to bit 0 at 0x5f\n";}
        $writestatus = $self->writeEeprom(00,'5f','0','0');
                         }
        if($sqlbit == 0){
	if($debug){print "Writing 1 to bit 0 at 0x5f\n";}
        $writestatus = $self->writeEeprom(00,'5f','0','1');
                         }
	if($verbose){
		if ($sqlbit == '0'){$toggled = 'SQUELCH';}
		else {$toggled = 'RFGAIN';}
		if ($writestatus eq 'OK') {print"RFGAIN Toggle to $toggled sucessfull!\n";}		    
		else {print"RFGAIN toggle failed: $writestatus\n";}
	  	    }
return $writestatus;
                      }





1;  # End of Ham::Device::FT817COMM
