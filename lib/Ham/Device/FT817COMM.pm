# This is the Yaesu FT-817 Command Library Module
# Written by Jordan Rubin 
# For use with the FT-817 Serial Interface
#
# $Id: FT817COMM.pm 2014-03-17 16:00:00Z JRUBIN $
#
# Copyright (C) 2014, Jordan Rubin
# jrubin@cpan.org 


package Ham::Device::FT817COMM;

use strict;
use 5.006;
use Digest::MD5 qw(md5);
use Data::Dumper;
our $VERSION = '0.9.0_06';

BEGIN {
	use Exporter ();
	use vars qw($OS_win $VERSION $debug $verbose $agreewithwarning $writeallow $syntaxerr 
		%SMETER %SMETERLIN %PMETER %AGCMODES %TXPWR %OPMODES $catoutput $output 
		$squelch $currentmode $out $vfo $home $tuneselect $nb $lock $txpow 
		$toggled $writestatus $testbyte $dsp $fasttuning $charger);

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
return $verbose;
               }

#### sets output of a set command
sub setWriteallow {
        my $self = shift;
        my $writeflag = shift;
        if($writeflag == '1') {our $writeallow = $writeflag;}
        if($writeflag == '0') {our $writeallow = undef;}
if ($writeallow){print "WRITING TO EEPROM ACTIVATED\n";}
if (!$writeallow){print "WRITING TO EEPROM DEACTIVATED\n";}
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
sub agreeWithwarning {
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



#### Decodes eeprom values from a given address and stips off second byte
sub eepromDecodenext {
        my $self  = shift;
        my ($MSB, $LSB) = @_;
        if ($debug){print "\neepromdecode:debug - Output from MSB:$MSB LSB:$LSB";}
        $MSB = hex($MSB);
        $LSB = hex($LSB);
        $self->{'port'}->write(chr($MSB).chr($LSB).chr(0).chr(0).chr(0xBB));
        $output = $self->{'port'}->read(2);
        $output = unpack("H*", substr($output,1,1));
	$output = hex($output);
        if ($debug){print " : $output\n";}
return $output;
                     }





#### Writes data to the eeprom MSB,LSB,BIT# and VALUE,  REWRITES NEXT MEMORY ADDRESS
sub writeEeprom {
        my $self=shift;
	my ($writestatus) = @_;
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
        $output = $self->{'port'}->read(2);
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


#### Writes an entire byte of data to the eeprom, MSB LSB VALUE
sub writeBlock {
        my $self=shift;
        my ($writestatus) = @_;
        my $MSB=shift;
        my $LSB=shift;
        my $VALUE=shift;

        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose == '2'){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
                if ($verbose == '1'){ print "Writing to EEPROM disabled and must be enabled before use....\n";}
                $writestatus = "Write Disabled";
return $writestatus;
				                             }
	my $addressname = $LSB;
        $MSB = hex($MSB);
        $LSB = hex($LSB);
	$VALUE = hex($VALUE);
        $self->{'port'}->write(chr($MSB).chr($LSB).chr(0).chr(0).chr(0xBB));
        my $output = $self->{'port'}->read(2);
        my $BYTE2 = unpack("H*", substr($output,1,1));
	$BYTE2 = hex($BYTE2);
	if($debug){print "MSB: $MSB   LSB: $LSB     1:$VALUE 2:$BYTE2 \n";}
        $self->{'port'}->write(chr($MSB).chr($LSB).chr($VALUE).chr($BYTE2).chr(0xBC));
	$output = $self->{'port'}->read(2);
	if($debug){print "READING NEW VALUES AT $MSB, $LSB\n";}
        $self->{'port'}->write(chr($MSB).chr($LSB).chr(0).chr(0).chr(0xBB));
	my $output2 = $self->{'port'}->read(2);
        if ($debug){print "Should be: ($VALUE) ($BYTE2)\n\n";}
        if ($output2 == $output) {
                $writestatus = "OK";
                if($debug){print "Values match\n";}}
        else {
                $writestatus = "ERROR, Run restoreEeprom($addressname) to return memory area to default";
                if($debug){print "Values did not match\n";}}
return $writestatus;
               }



#### Restores eprom memory address to pre written default value in case there was an error
# Currently supports address (5f 62 7b)
sub restoreEeprom {
        my $self=shift;
        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose == '2'){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
                if ($verbose == '1'){ print "Writing to EEPROM disabled and must be enabled before use....\n";}
                $writestatus = "Write Disabled";
return $writestatus;
                          }
        my ($area,$MSB,$LSB,$writestatus,$testbyte1,$testbyte2,$test,$restorevalue,$address) = @_;
	if (($area ne '5f') && ($area ne '62') && ($area ne '7b') && ($area ne '7a') && ($area ne '79') && ($area ne '5d')){
		if($debug || $verbose){print "Address ($area) not supported for restore...\n";}
		$writestatus = "Invalid memory address ($area)";
return $writestatus;
			  }


        if ($area eq '5d'){
                $address = '93'; $restorevalue = '66';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x5D\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'Resume Scan','OFF', 'PKT Rate','1200', 'Scope','CONT', 'CW-ID', 'OFF', 'Main STEP','FINE', 'ARTS','RANGE';
                             }
                          }

        if ($area eq '5f'){
		$address = '95'; $restorevalue = '229';
		if ($verbose){
			print "\nDEFAULTS LOADED FOR 0x5F\n";
			print "________________________\n";
			printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'CW Weight','1:3', '430 ARS','ON', '144 ARS','ON', 'SQL-RFG', 'SQUELCH';
			     }			
			  } 

        if ($area eq '62'){
		$address = '98'; $restorevalue = '72';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x62\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n\n", 'CW Speed','12wpm', 'Chargetime','8hrs';
                             }
		  	  }

        if ($area eq '79'){
                $address = '121'; $restorevalue = '3';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x79\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'TX Power','LOW1', 'PRI','OFF', 'DUAL-WATCH', 'OFF', 'SCAN', 'OFF', 'ARTS', 'OFF';
                             }
			  }

        if ($area eq '7a'){
		$address = '122'; $restorevalue = '15';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x7A\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n\n", 'Antennas','All Rear except VHF and UHF', 'SPL','OFF';
                             }
			  }
        if ($area eq '7b'){
	$address = '123'; $restorevalue = '8';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x7B\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n\n", 'Chargetime','8hrs', 'Charger','OFF';
                             }
			  }

	my $nextvalue = $self->eepromDecodenext('00',"$area");
        $self->{'port'}->write(chr(0).chr("$address").chr("$restorevalue").chr("$nextvalue").chr(0xBC));
        $writestatus = $self->{'port'}->read(2);

return $writestatus;
		  }

###############################
#CAT COMMANDS IN ORDER BY BOOK#
###############################



#### ENABLE/DISABLE LOCK VIA CAT
sub setLock {
        my ($data) = @_;
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
        my ($data) = @_;
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
	my ($badf,$f1,$f2,$f3,$f4) = @_;
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
	my ($data) = @_;
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
	my ($badf,$f1,$f2,$p) = @_;
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
	my ($data) = @_;
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
	my ($datablock) = @_;
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
	my ($badf,$f1,$f2,$f3,$f4) = @_;
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
	my ($badf,$f1,$f2) = @_;
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
	my ($badf,$f1,$f2) = @_;
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
        my ($match,$desc) = @_;
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
        my ($match,$desc,$ptt,$highswr,$split) = @_;
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
	my ($freq) = @_;
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
        my ($data) = @_;
	my $self=shift;
	my $powerset = shift;
	$data = undef;
        if ($verbose){
                if (!$powerset) {print "Option ON / OFF Missing.\n"; return 1;}
                if (($powerset) && ($powerset ne 'ON') && ($powerset ne 'OFF')) 
				 {
				print "Syntax Error.\n"; return 'error';
	                         }
			
		    }

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
        my $self=shift;
	my $address =shift;
	my $address2 = shift;


        if ($verbose){
		if (!$address) {
                print "Get EEPROM ($address) Failed. Must contain  hex value 0-9 a-f.\n"; 
return 1;
			       }
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
        my ($confighex4,$confighex5,$output4,$output5) = @_;
        my $self=shift;
	my $type=shift;
        $output4 = $self->eepromDecode(00,04);
	$confighex4 = sprintf("%x", oct( "0b$output4" ) );
        $output5 = $self->eepromDecode(00,05);
        $confighex5 = sprintf("%x", oct( "0b$output5" ) );
	my $configoutput = "[$confighex4][$confighex5]";
        $out = "\nHardware Jumpers created value of\n0x04[$output4]($confighex4)\n0x05[$output5]($confighex5)\n\n";
        if($verbose){
                print "$out";
	            }
return $configoutput;
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
	my $digestdata = undef;

	if ($option eq 'console') {
		if ($verbose){
		print "\n";
		printf "%-11s %-15s %-11s %-11s\n", 'ADDRESS', 'BINARY', 'DECIMAL', 'VALUE';
		print "___________________________________________________\n";
			     }
	                          }


        if ($verbose && $option eq 'digest'){
                print "Generated an MD5 hash from software calibration values ";
                     }


        if ($option eq 'file'){
		if (!$filename) {print"\nFilename required.     eg. /home/user/softcal.txt\n";return 0;}
		if (-e $filename) {
			print "\nFile exists. Backup/rename old file before creating new one.\n";
			return 0;
				  }
		else {
			$buildfile = '1';
			if ($verbose){print "\nCreating calibration backup to $filename........\n";}
			open  FILE , ">>", "$filename" or print"Can't open $filename. error\n";
			print FILE "FT817 Software Calibration Backup\nUsing FT817COMM.pm version $VERSION\n";
			print FILE "Created $localtime\n\n";
			printf FILE "%-11s %-15s %-11s %-11s\n", 'ADDRESS', 'BINARY', 'DECIMAL', 'VALUE';
                	print FILE "___________________________________________________\n";
		     }
                              }


###################

	if ($option eq 'digest') {

        do {
                my $memoryaddress = sprintf("0x%x",$startaddress);
                my $valuebin = $self->eepromDecode(00,"$memoryaddress");
                my $valuehex = sprintf("%x", oct( "0b$valuebin" ) );

		$digestdata .="$valuehex";

                $block++;
                $startaddress ++;
           }
        while ($block < '78');

		my $digest = md5($digestdata);
		if ($verbose) {print "DIGEST: ---->$digest<----\n";}
		return $digest;
      			 }


##################

#################

	else {

	do {
		my $memoryaddress = sprintf("0x%x",$startaddress);
		my $valuebin = $self->eepromDecode(00,"$memoryaddress");
		my $valuehex = sprintf("%x", oct( "0b$valuebin" ) );
		my $valuedec = hex($valuehex);
	if ($option eq 'console' || $verbose) {
		printf "\n%-11s %-15s %-11s %-11s\n", "$memoryaddress", "$valuebin", "$valuedec", "$valuehex";
				  }
	if ($buildfile == '1'){
               printf FILE "%-11s %-15s %-11s %-11s\n", "$memoryaddress", "$valuebin", "$valuedec", "$valuehex";
			      }

		$block++;
		$startaddress ++;
	   }
	while ($block < '78');


            }
##################


        if ($buildfile == '1'){
                print FILE "\n\n---END OF Software Calibration Settings---\n";
                close FILE;
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
		if($home eq'Y'){print "At Home Frequency.\n";}
		if($home eq 'N'){print "Not at Home Frequency\n";}
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
        if($verbose == '1'){
                print "DSP is $dsp\n";
                           }
        if($verbose == '2'){ 
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
                print "Fast Tuning is $fasttuning\n";
                           }
        if($verbose == '2'){
                print "getFasttuning: bit is ($block55[0]) Fast Tuning is $fasttuning\n";
                           }
return $fasttuning;
           }


# 5d ################################# GET ARTS BEEP MODE ######
###################################### READ BIT 6-7 FROM 0X5d

sub getArtsmode {
        my ($artsmode) = @_;
        my $self=shift;
        $output = $self->eepromDecode(00,'5d');
        $artsmode = substr($output,0,2);
        if ($artsmode == '00'){$artsmode = 'OFF'};
        if ($artsmode == '01'){$artsmode = 'RANGE'};
        if ($artsmode == '10'){$artsmode = 'ALL'};
        if($verbose){
                print "ARTS BEEP is ($artsmode)\n";
                    }
return $artsmode;

		}

# 5f ################################# GET RFGAIN/SQUELCH ######
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



# 79 ################################# GET TX POWER AND ARTS ######
###################################### READ BIT 0-1 AND 7 FROM 0X79

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


sub getArts {
        my ($artsis) = @_;
        my $self=shift;
        $output = $self->eepromDecode(00,79);
        my $arts = substr($output,0,1);
	if ($arts == '0'){$artsis = 'OFF'};
        if ($arts == '1'){$artsis = 'ON'};

        if($verbose == '1'){
                print "ARTS is $artsis\n";
                           }
        if($verbose == '2'){
                print "getArts: bits are ($arts) ARTS is $artsis\n";
                           }
return $artsis;
               }



# 7a ################################# GET ANTENNA STATUS ######
###################################### READ 0-5 BITS FROM 0X7A

sub getAntenna {
        my ($antenna, %antennas, %returnant) = @_;
        my $self=shift;
	my $value=shift;
	my $ant;
        $output = $self->eepromDecode(00,'7a');

        if ($value eq 'HF'){$antenna = substr($output,7,1);}
        if ($value eq '6M'){$antenna = substr($output,6,1);}
        if ($value eq 'FMBCB'){$antenna = substr($output,5,1);}
        if ($value eq 'AIR'){$antenna = substr($output,4,1);}
        if ($value eq 'VHF'){$antenna = substr($output,3,1);}
        if ($value eq 'UHF'){$antenna = substr($output,2,1);}


	if ($antenna == 0){$ant = 'FRONT';}
        if ($antenna == 1){$ant = 'BACK';}
	
	if ($value && $value ne 'ALL'){
        if($verbose == '1'){
                print "\nAntenna [$value] is set to $ant\n\n";
                           }
        if($verbose == '2'){
                print "\ngetAntenna: bits are ($antenna) Antenna [$value] is set to $ant\n\n";
                           }
			    }

	if (!$value || $value eq 'ALL'){

	%antennas = ('HF', 7, '6M', 6, 'FMBCB', 5, 'AIR', 4, 'VHF', 3, 'UHF', 2);
	my $key;
	print "\n";
foreach $key (sort keys %antennas) {
	$antenna = substr($output,$antennas{$key},1);
        if ($antenna == 0){$ant = 'FRONT';}
        if ($antenna == 1){$ant = 'BACK';}
	printf "%-11s %-11s %-11s %-11s\n", 'Antenna', "$key", "set to", "$ant";
	$returnant{$key} = $ant;

 				   }
	print "\n";
return %returnant;

				       }

return $ant;
               }


# 7b ################################# GET BATTERY CHARGE STATUS ######
###################################### READ BIT 0-3 and 4 FROM 0X7B

sub getCharger {
        my $self=shift;
        $output = $self->eepromDecode(00,'7b');
	my $test = substr($output,3,1);
	my $time = substr($output,4,4);
        my $timehex = sprintf("%x", oct( "0b$time" ) );
	$time = hex($timehex);

        if ($test == '0') {$charger = "OFF";}
        if ($test == '1') {$charger = "ON";}

	if ($charger eq 'OFF'){
        if($verbose){
                print "Charger is $charger: Timer configured for $time hours\n";
                    }
			      }

	        if ($charger eq 'ON'){
        if($verbose){
                print "Charging is $charger: Set for $time hours\n";
                    }
                                     }
return $charger;
           
	       }


#################################
# WRITE VALUES FROM EEPROM ADDR #
#################################


# 5d ################################# SET ARTS MODE BIT
###################################### TOGGLE BIT 0 FROM ADDRESS 0X5D

sub setArtsmode {
        my ($chargebits, $currentartsmode) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'OFF' && $value ne 'ALL' && $value ne 'RANGE'){
                if($verbose){print "Value invalid: Choose OFF/ALL/RANGE\n\n"; }
return 1;
								    }


        $self->setVerbose(0);
        $currentartsmode = $self->getArtsmode();
        $self->setVerbose(1);

        if ($value eq $currentartsmode){
                if($verbose){print "Value $currentartsmode already selected.\n\n"; }
return 1;
                                       }

        my $BYTE1 = $self->eepromDecode('0','5d');
        if ($value eq 'OFF'){substr ($BYTE1, 0, 2, '00');}
        if ($value eq 'RANGE'){substr ($BYTE1, 0, 2, '01');}
        if ($value eq 'ALL'){substr ($BYTE1, 0, 2, '10');}
        my $NEWHEX = sprintf("%x", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('00','5d',"$NEWHEX");


        if($verbose){
                if ($writestatus eq 'OK') {print"ARTS Mode Set to $value sucessfull!\n";}
                else {print"ARTS Mode set failed: $writestatus\n";}
                $writestatus = 'ERROR';
                    }
return $writestatus;
		 }


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


# 62 ################################# SET CHARGETIME
###################################### CHANGE BITS 6-7 FROM ADDRESS 0X62

sub setChargetime {
        my ($chargebits, $writestatus1, $writestatus2, $writestatus3, $writestatus4, $writestatus5, $writestatus6, $changebits, $change7bbit) = @_;
        my $self=shift;
	my $value=shift;
        $output = $self->eepromDecode(00,'62');
        $chargebits = substr($output,0,2);
	print "Checking : ";
	my $chargerstatus = $self->getCharger();
        if ($chargerstatus eq 'ON'){
                if($verbose){print "Charger is running: You must disable it first before setting an new chargetime.\n\n"; }
return 1;
                                                       }
        if($debug){print "Currently set at value ($chargebits) at 0x62\n";}
	if ($value != 10 && $value != 6 && $value != 8){
	        if($verbose){print "Time invalid: Use 6 or 8 or 10.\n\n"; }

return 1;
	 					       }
	else {
		my $six = '00'; my $eight = '01'; my $ten = '10';
			if (($value == 6 && $chargebits == $six) || 
		   	    ($value == 8 && $chargebits == $eight) ||
			    ($value == 10 && $chargebits == $ten)) {
				print "Current charge time $value already set.\n";
return 1;
								 }
	     }

        if($debug){print "Writing New BYTES to 0x62\n";}

	my $BYTE1 = $self->eepromDecode('0','62');
	if ($value == '6'){substr ($BYTE1, 0, 2, '00');}
        if ($value == '8'){substr ($BYTE1, 0, 2, '01');}
        if ($value == '10'){substr ($BYTE1, 0, 2, '10');}
        my $NEWHEX = sprintf("%x", oct( "0b$BYTE1" ) );
	$writestatus = $self->writeBlock('00','62',"$NEWHEX");

        if($debug){print "Writing New BYTES to 0x62\n";}
        if($debug){print "Writing New BYTES to 0x7b\n";}

        $BYTE1 = $self->eepromDecode('0','7b');
        if ($value == '6'){substr ($BYTE1, 4, 4, '0110');}
        if ($value == '8'){substr ($BYTE1, 4, 4, '1000');}
        if ($value == '10'){substr ($BYTE1, 4, 4, '1010');}
        $NEWHEX = sprintf("%x", oct( "0b$BYTE1" ) );	
         $writestatus2 = $self->writeBlock('00','7b',"$NEWHEX");


        if($verbose){
                if (($writestatus eq 'OK' && $writestatus2 eq 'OK')) {print"Chargetime Set to $value sucessfull!\n";}
                else {print"Chargetime set failed: $writestatus\n";}
		$writestatus = 'ERROR';
                    }

return $writestatus;
                      }


# 79 ################################# SET ARTS ON/OFF
###################################### CHANGE BITS 7 FROM ADDRESS 0X79

sub setArts {
       my ($currentarts, $writestatus) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n"; }
return 1;
					      }
        $self->setVerbose(0);
        $currentarts = $self->getArts();
        $self->setVerbose(1);

        if ($value eq $currentarts){
                if($verbose){print "Value $currentarts already selected.\n\n"; }
return 1;
                                   }


        if($value eq 'ON'){$writestatus = $self->writeEeprom(00,'79','0','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom(00,'79','0','0');}

	if ($verbose){
                if ($writestatus eq 'OK') {print"ARTS set to $value sucessfull!\n";}
                else {print"ARTS set to $value failed!!!\n";}
		     }

return $writestatus;
            }



# 7a ################################# SET ANTENNA FRONT/BACK
###################################### CHANGE BITS 0-5 FROM ADDRESS 0X7A

sub setAntenna {
       my ($currentantenna, $antennabit) = @_;
        my $self=shift;
        my $value=shift;
        my $value2=shift;

        if ($value ne 'HF' && $value ne '6M' && $value ne 'FMBCB' && $value ne 'AIR' && $value ne 'VHF' && $value ne 'UHF'){
                if($verbose){print "Value invalid: Choose HF/6M/FMBCB/AIR/VHF/UHV\n\n"; }
return 1;															  
															   }

        if ($value2 ne 'FRONT' && $value2 ne 'BACK'){
                if($verbose){print "Value invalid: Choose FRONT/BACK\n\n"; }
return 1;
                                                                                                                           }
        $self->setVerbose(0);
	$currentantenna = $self->getAntenna("$value");
	$self->setVerbose(1);

	if ($currentantenna eq $value2) {
                if($verbose){print "\nAntenna for $value is already set to $value2\n\n"; }
return 1;
					}

	my $valuelabel = $value2;

	if ($value2 eq 'BACK'){$value2 = 1;}
        if ($value2 eq 'FRONT'){$value2 = 0;}
	if ($value eq 'HF'){$antennabit = 7;}
        if ($value eq '6M'){$antennabit = 6;}
        if ($value eq 'FMBCB'){$antennabit = 5;}
        if ($value eq 'AIR'){$antennabit = 4;}
        if ($value eq 'VHF'){$antennabit = 3;}
        if ($value eq 'UHF'){$antennabit = 2;}

        $writestatus = $self->writeEeprom(00,'7a',"$antennabit","$value2");

                if($verbose && $writestatus eq 'OK'){print "\nAntenna for $value set to $valuelabel: $writestatus\n\n"; }
                if($verbose && $writestatus ne 'OK'){print "\nError setting antenna: $writestatus\n\n"; }
return $writestatus;
 	       }


# 7b ################################# SET CHARGER ON/OFF
###################################### CHANGE BITS 6-7 FROM ADDRESS 0X7b

sub setCharger {
        my $self=shift;
        my $value=shift;
	my $chargerstatus = $self->getCharger();

        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Use ON or OFF.\n\n"; }

return 1;
                                              }

	if ($chargerstatus eq $value){
		print "Staying $value\n";
return 1;
				     }

	else {
                print "Turning $value\n";
###### WORK HERE
        if ($value eq 'OFF'){$writestatus = $self->writeEeprom(00,'7b','3','0');}
	if ($value eq 'ON'){$writestatus = $self->writeEeprom(00,'7b','3','1');}
return 0;
	     }




return 1;

               }






=head1 NAME

Ham::Device::FT817COMM - Library to control the Yaesu FT817 Ham Radio

=head1 VERSION

Version 0.9.0_06

=head1 SYNOPSIS

use HAM::Device::FT817COMM;

=head2 Constructor and Port Configurations


	my $FT817 = new Ham::Device::FT817COMM (
	serialport => '/dev/ttyUSB0',
	baud => '38400',
	lockfile => '/var/lock/ft817'
				               );

	my $port = $FT817->{'serialport'};
	my $baud = $FT817->{'baud'};
	my $lockfile = $FT817->{'lockfile'};
	my $version = $FT817->moduleVersion;

=head2 Destructor

	$FT817->closePort;

=head2 Initialization

The instance of the device and options are created with the constructor and port configurations shown above.
The variable which is an instance of the device may be named at that point. In this case B<$FT817>.
The serialport must be a valid port and not locked.  You must consider that your login must have 
permission to access the port either being added to the group or giving the user suffucient privilages.
The baudrate 'baud' must match the baudrate of the radio B<CAT RATE> which is menu item B<14>.

Finally B<lockfile> is recommended to ensure that no other software may access the port at the same time.
The lockfile is removed as part of the invocation of the destructor method.


=head1 METHODS

=head2 1. Using Return Data From a Module

This allows for complete control of the rig through the sub routines
all done through the cat interface

        $output = 'rigname'->'command'('value');

an example is a follows

	$output = $FT817->setLock('ENABLE');

Using this method, the output which is collected in the varible B<$output> is designed to be minimal for
use in applications that provide an already formatted output.

For example:
	
	$output = $FT817->setLock('ENABLE');
	print "$output";

Would simply return B<F0> if the command failed and B<00> if the command was sucessfull. The outputs vary
from module to module, depending on the function

=head2 2. Using setVerbose()

The module already has pre-formatted outputs for each subroutine.  Using the same example in a different form
and setting B<setVerbose(1)> we have the following

	setVerbose(1);
	$FT817->setLock('ENABLE');

The output would be, for example:
	
	Set Lock (ENABLE) Sucessfull.

Other verbose outputs exist to catch errors.

	setVerbose(1);
	$FT817->setLock('blabla');

The output would be:

	Set Lock (blabla) Failed. Option:blabla invalid.

The B<setVerbose(2)> flag is similar to the setVerbose(1) flag but also provides the bit value of the function at
the specified memory address.

An example of all 3 is show below for the command getHome()

	As return data: Y
	As verbose(1) : At Home Frequency
	As verbose(2) : getHome: bit is (1) Home is Y

We see that return data will be suitable for a program which needs just a boolean value, verbose(1) is suitable
for a front-end app response, and verbose(2) for internal testing of module.

=head2 3. Build a sub-routine into a condition

Another use can be to use a subrouting as a value in a condition statment to test

	if ((gethome()) eq 'Y') {
		warn "I guess we're home";
			      }

Call all of the modules, one at a time and look at the outputs, from which you can decide how the data can be used.
At this time I have completed a command line front end for this module that makes testing all of the functionality easy.

=head1 DEBUGGER

FT817COMM has a built in robust debugger that makes available to the user all transactions between the software and the rig.
Where verbose gave the outputs to user initiated subroutines, the debugger does very much the same but with internal functions
not designed to be called directly in the userspace.  That being said, you should never directly call these system functions
or you will quickly turn your 817 into a paperweight or door stop. You have been warned.

Feel free to use the debugger to get an idea as to how the module and the radio communicate.

	setDebug(1); # Turns on the debugger

The first output of which is:

	DEBUGGER IS ON

Two distinct type of transactions happen with the debugger, they are:

	CAT commands   :	Commands which use the Yaesu CAT protocol
	EPROMM commands:	Commands which read and write to the EEPROM

With the command: B<getMode()> we get the regular output expected, with B<verbose(1)>

	Mode is FM

However with the B<setDebug(1)> we will see the following output to the same command:

	sendcat:debug - DATA OUT ----> 00 00 00 00 0x03
	sendcat:debug - DATA IN <----- 1471200008
	Mode is FM

The sendcat:debug shows the request of B<00 00 00 00 0x03> sent to the rig, and the rig
returning B<1471200008>. What were looking at is the last two digits 08 which is parsed from
the block of data.  08 is mode FM.  FT817COMM does all of the parsing and conversion for you.

As you might have guessed, the first 8 digits are the current frequency, which in this case
is 147.120 MHZ.  The getFrequency() module would pull the exact same data, but parse it differently

The debugger works differently on read/write to the eeprom. The next example shown below used the function
B<getNb()>, the noiseblocker status.

	eepromdecode:debug - Output from MSB:0 LSB:57 : 11000010
	Noise Blocker is OFF

The output shows that the status of noise blocker lives at B<0x57> it happens to be bit B<5> of this data B<(0)> that
indicates that the noiseblocker is B<OFF>.


=head1 Modules

=over

=item agreeWithwarning()

		$agree = $FT817->agreeWithwarning(#);

	Turns on and off the internal flag that says. You undrstand the risks of writing to the EEPROM
	Activated when any value is in the (). Good practive says () or (1) for OFF and ON.

	Returns the argument sent to it on success.

=item closePort()

		$FT817->closePort();

	This function should be executed at the end of the program.  This closes the serial port and removed the lock
	file if applicable.  If you do not use this, and exit abnormally, you will need to manually remove the lock 
	file if it was enabled in the settings.


=item dec2bin()

	Simple internal function for converting decimal to binary. Has no use to the end user.

=item eepromDecode()

	An internal function to retrieve code from an address of the eeprom and convert the first byte to 
	binary, dumping the second byte.


=item eepromDecodenext()

        An internal function to retrieve code from an address of the eeprom  returning hex value of the next
	memory address up.


=item getAgc()

		$agc = $FT817->getAgc();

	Returns the current setting of the AGC: AUTO / FAST / SLOW / OFF

=item getAntenna ()

                $antenna = $FT817->getAntenna({HF/6M/FMBCB/AIR/VHF/UHF});
                %antenna = $FT817->getAntenna({ALL});
		%antenna = $FT817->getAntenna();

	Returns the FRONT/BACK configuration of the antenna for the different types of
	bands.  Returns one value when an argument is used.  If the argument ALL or no
	argument is used will print a list of the configurations or all bands and returns
	a hash or the configuration


=item getArts ()

		$arts = $FT817->getArts();

	Returns the status of ARTS: ON / OFF


=item getArtsmode ()

                $artsmode = $FT817->getArtsmode();

        Returns the status of ARTS BEEP: OFF / RANGE /ALL

=item getCharger()

                $charger = $FT817->getCharger();

        Returns the status of the battery charger.  Verbose will show the status and if the
	status is on, how many hours the battery is set to charge for.


=item getConfig()

		$config = $FT817->getConfig();

	Returns the two values that make up the Radio configuration.  This is set by the soldier blobs
	of J4001-J4009 in the radio.

=item getDsp()

		$dsp = $FT817->getDsp();

	Returns the current setting of the Digital Signal Processor (if applicable) : ON / OFF

=item getEeprom()

		$value = $FT817->getEeprom();

	Currently returns just the value you send it. In verbose mode however, it will display a formatted
	output of the memory address specified.  This was added late and will be update in the next release. 

=item getFasttuning()

		$fasttune = $FT817->getFasttuning();

	Returns the current setting of the Fast Tuning mode : ON / OFF

=item getFlags()

		$flags = $FT817->getFlags();

	Returns the current status of the flags : DEBUG / VERBOSE / WRITE ALLOW / WARNED

=item getFrequency()

		$frequency = $FT817->getFrequency(#);

	Returns the current frequency of the rig eg. B<14712000> with B<getFrequency()>
	Returns the current frequency of the rig eg. B<147.120.00> MHZ with B<getFrequency(1)>

=item getHome()

		$home = $FT817->getHome();

	Returns the current status of the rig being on the Home Frequency : Y/N

=item getLock()

		$lock = $FT817->getLock();

	Returns the current status of the lock function being enable : Y/N

=item getMode()

		$mode = $FT817->getMode();

	Returns the current Mode of the Radio : AM / FM / USB / CW etc.......


=item getNb()

		$nb = $FT817->getNb();

	Returns the current Status of the Noise Blocker : ON / OFF

=item getRfgain()

		$rfgainknob = $FT817->getRfgain();

	Returns the current Functionality of the RF-GAIN Knob : RFGAIN / SQUELCH

=item getRxstatus()

		$rxstatus = $FT817->getRxstatus({variables/hash});

	Retrieves the status of SQUELCH / S-METER / TONEMATCH / DESCRIMINATOR in one
	command and posts the information when verbose(1).  

	Returns with variables as argument $squelch $smeter $smeterlin $desc $match
	Returns with hash as argument %rxstatus

=item getSoftcal()

		$softcal = $FT817->getSoftcal({console/digest/file filename.txt});

	This command currently works with verbose and write to file.  Currently there is no
	usefull return information Except for digest.  With no argument, it defaults to 
	console and dumps the entire 76 software calibration memory areas to the screen. 
	Using digest will return an md5 hash of the calibration settings. Using file along
	with a file name writes the output to a file.  It's a good idea to keep a copy of 
	this in case the eeprom gets corrupted and the radio factory defaults.  If you dont have 
	this information, you will have to send the radio back to the company for recalibration.

=item getTuner()

		$tuner = $FT817->getTuner();

	Returns the current tuner setting : VFO / MEMORY

=item getTxpower()

		$txpower = $FT817->getTxpower();

	Returns the current Transmit power level : HIGH / LOW3 / LOW2 / LOW1

=item getTxstatus()

		$txstatus = $FT817->getTxstatus({variables/hash});

	Retrieves the status of POWERMETER / PTT / HIGHSWR / SPLIT in one
	command and posts the information when verbose(1).  

	Returns with variables as argument $pometer $ptt $highswr $split
	Returns with hash as argument %txstatus

=item getVfo()

		$vfo = $FT817->getVfo();

	Returns the current VFO : A / B

=item hex2bin()

	Simple internal function for convrting hex to binary. Has no use to the end user.

=item moduleVersion()

		$version = $FT817->moduleVersion();

	Returns the version of FT817COMM.pm to the software calling it.

=item new()

		my $FT817 = new Ham::Device::FT817COMM (
		serialport => '/dev/ttyUSB0',
		baud => '38400',
		lockfile => '/var/lock/ft817'
					               );

	Creates an instance of the device that is the Radio.  Called at the begining of the program.
	See the Constructors section for more info.


=item restoreEeprom()

		$restorearea = $FT817->restoreEeprom();

	This restores a specific memory area of the EEPROM back to a known good default value.
	This is a WRITEEEPROM based function and requires both setWriteallow() and agreeWithwarning()
	to be set to 1.
	This command does not allow for an arbitrary address to be written. Currently 5d, 5f, 62, 79, 7a 
	and 7b are allowed

	restoreEeprom('5f'); 

	Returns 'OK' on success. Any other output an error.

=item sendCat()

	Internal function, if you try to call it, you may very well end up with a broken radio.
	You have been warned.

=item setAntenna()

                $status = $FT817->setAntenna([HF/6M/FMBCB/AIR/VHF/UHF][FRONT/BACK]);

	Sets the antenna for the given band as connected on the FRONT or REAR of the radio

	This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('7a');


=item setArts()

                $arts = $FT817->setArts([ON/OFF]);

	Sets the ARTS function of the radio to ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('79');


=item setArtsmode()

                $artsmode = $FT817->setArts([OFF/RANGE/BEEP]);

        Sets the ARTS function of the radio when ARTS is enables

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('5d');

=item setCharger()

                $charger = $FT817->setCharger([ON/OFF]);

        Turns the battery Charger on or off
	This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('7b');



=item setChargetime()

                $chargetime = $FT817->setChargetime([6/8/10]);

        Sets the Battery charge time to 6, 8 or 10 hours.  If the charger is currently
	on, it will return an error and not allow the change. Charger must be off.
	This is a WRITEEEPROM based function and requires both setWriteallow() and
	agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        commands that also requires both flags previously mentioned set to 1.

        restoreEeprom('62');
	restoreEeprom('7b');

        Returns 'OK' on success. Any other optput an error.


=item setClarifier()

		$setclar = $FT817->setClarifier({enable/disable});

	Enables or disables the clarifier

	Returns '00' on success or 'f0' on failure

=item setClarifierfreq()

		$setclarfreq = $FT817->setClarifierfreq(####);

	Uses 4 digits as an argument to set the Clarifier frequency.  Leading and trailing zeros required where applicable
	 1.234 KHZ would be 1234

	Returns '00' on success or 'f0' on failure

=item setCtcssdcs()

		$ctcssdcs = $FT817->setCtcssdcs({DCS/CTCSS/ENCODER/OFF});

	Sets the CTCSS DCS mode of the radio

	Returns 'OK' on success or something else on failure

=item setCtcsstone()

		$ctcsstone = $FT817->setCtcsstone(####);

	Uses 4 digits as an argument to set the CTCSS tone.  Leading and trailing zeros required where applicable
	 192.8 would be 1928 as an argument

	Returns '00' on success or 'f0' on failure

=item setDcscode()

		$dcscode = $FT817->setDcscode(####);

	Uses 4 digits as an argument to set the DCS code.  Leading and trailing zeros required where applicable
	 0546 would be 546 as an argument

	Returns '00' on success or 'f0' on failure

=item setDebug()

		$debug = $FT817->setDebug(#);

	Turns on and off the internal debugger. Provides information on all serial transactions when on.
	Activated when any value is in the (). Good practive says () or (1) for OFF and ON.

	Returns the argument sent to it on success.

=item setFrequency()

		$setfreq = $FT817->setFrequency(########);

	Uses 8 digits as an argument to set the frequency.  Leading and trailing zeros required where applicable
	147.120 MHZ would be 14712000
	 14.070 MHZ would be 01407000

	Returns '00' on success or 'f0' on failure

=item setLock()

		$setlock = $FT817->setLock({enable/disable});

	Enables or disables the radio lock.

	Returns '00' on success or 'f0' on failure

=item setMode()

		$setmode = $FT817->setMode({LSB/USB/CW/CWR/AM/FM/DIG/PKT/FMN/WFM});

	Sets the mode of the radio with one of the valid modes.

	Returns '00' on success or 'f0' on failure

=item setOffsetfreq()

		$offsetfreq = $FT817->setOffsetfreq(########);

	Uses 8 digits as an argument to set the offset frequency.  Leading and trailing zeros required where applicable
	1.230 MHZ would be 00123000

	Returns '00' on success or 'f0' on failure

=item setOffsetmode()

		$setoffsetmode = $FT817->setOffsetmode({POS/NEG/SIMPLEX});

	Sets the mode of the radio with one of the valid modes.

	Returns '00' on success or 'f0' on failure

=item setPower()

		$setPower = $FT817->setPower({ON/OFF});

	Sets the power of the radio on or off. Note that this function, as stated in the manual only works
	Correctly when connected to DC power and NO Battery installed 

	Returns '00' on success or 'null' on failure

=item setPtt()

		$setptt = $FT817->setPtt({ON/OFF});

	Sets the Push to talk of the radio on or off.  

	Returns '00' on success or 'f0' on failure

=item setSplitfreq()

		$setsplit = $FT817->setSplitfreq({enable/disable});

	Sets the radio to split the transmit and receive frequencies

	Returns '00' on success or 'f0' on failure

=item setWriteallow()

		$writeallow = $FT817->setWriteallow(#);

	Turns on and off the write Flag. Provides a warning about writing to the EEPROM and
	requires the agreeWithwarning()  to also be set to 1 after reading the warning
	Activated when any value is in the (). Good practive says () or (1) for OFF and ON.

	Returns the argument sent to it on success.

=item toggleRfgain()

		$togglerf = $FT817->toggleRfgain();

	Toggles the RF-GAIN knob between RFGAIN or SQLELCH.  This is a WRITEEEPROM based
	function and requires both setWriteallow() and agreeWithwarning() to be set to 1.
	In the event of a failure, the memory area can be restored with. The following
	command that also requires both flags previously mentioned set to 1.

	restoreEeprom('5f'); 

	Returns 'OK' on success. Any other optput an error.

=item vfoToggle()

		$vfotoggle = $FT817->vfotoggle();

	Togles the VFO between A and B

	Returns '00' on success or 'f0' on failure


=item writeBlock()

	Internal function, if you try to call it, you may very well end up with a broken radio.
        You have been warned.


=item writeEeprom()

	Internal function, if you try to call it, you may very well end up with a broken radio.
	You have been warned.

=back

=head1 AUTHOR

Jordan Rubin KJ4TLB, C<< <jrubin at cpan.org> >>

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


1;  # End of Ham::Device::FT817COMM
