# This is the Yaesu FT-817 Command Library Module
# Written by Jordan Rubin 
# For use with the FT-817 Serial Interface
#
# $Id: FT817COMM.pm 2014-03-23 12:00:00Z JRUBIN $
#
# Copyright (C) 2014, Jordan Rubin
# jrubin@cpan.org 


package Ham::Device::FT817COMM;

use strict;
use 5.006;
use Digest::MD5 qw(md5);
#use Data::Dumper;
our $VERSION = '0.9.0_10';

BEGIN {
	use Exporter ();
	use vars qw($OS_win $VERSION $debug $verbose $agreewithwarning $writeallow $syntaxerr 
		%SMETER %SMETERLIN %PMETER %AGCMODES %TXPWR %OPMODES %VFOBANDS %VFOABASE %VFOBBASE 
		%HOMEBASE %MEMMODES %FMSTEP %AMSTEP %CTCSSTONES %DCSCODES $catoutput $output $squelch
		$currentmode $out $vfo $home $tuneselect $nb $lock $txpow $toggled $writestatus
		$testbyte $dsp $fasttuning $charger);

my $ft817;
my $catoutput;
my $currentmode;
my $output;

our $syntaxerr = "SYNTAX ERROR, CHECK WITH VERBOSE('1')\n";

our %AGCMODES = (AUTO => '00', FAST => '01', SLOW => '10', OFF => '11');

our %MEMMODES = (LSB => '000', USB => '001', CW => '010', CWR => '011', AM => '100', 
		FM => '101', DIG => '110', PKT => '111');

our %FMSTEP = ('5.0' => '000', '6.25' => '001', '10.0' => '010', '12.5' => '011', '15.0' => '100',
               '20.0' => '101', '25.0' => '110', '50.0' => '111');

our %AMSTEP = ('2.5' => '000', '5.0' => '001', '9.0' => '010', '10.0' => '011', '12.5' => '100',
               '25.0' => '101');

our %CTCSSTONES = ('000000' => '67.0', '000001' => '69.3', '000010' => '71.9', '000011' => '74.4',
                   '000100' => '77.0', '000101' => '79.7', '000110' => '82.5', '000111' => '85.4',
                   '001000' => '88.5', '001001' => '91.5', '001010' => '94.8', '001011' => '97.4',
                   '001100' => '100.0', '001101' => '103.5', '001110' => '107.2', '001111' => '110.9', 
	           '010000' => '114.8', '010001' => '118.8', '010010' => '123.0', '010011' => '127.3',
	           '010100' => '131.8', '010101' => '136.5', '010110' => '141.3', '010111' => '146.2', 
	           '011000' => '151.4', '011001' => '156.7', '011010' => '159.8', '011011' => '162.2', 
                   '011100' => '165.5', '011101' => '167.9', '011110' => '171.3', '011111' => '173.8',
	           '100000' => '177.3', '100001' => '179.9', '100010' => '183.5', '100011' => '186.2',
                   '100100' => '189.6', '100101' => '192.8', '100110' => '196.6', '100111' => '199.5',
                   '101000' => '203.5', '101001' => '206.5', '101010' => '210.7', '101011' => '218.1',
                   '101100' => '225.7', '101101' => '229.1', '101110' => '233.6', '101111' => '241.8',
                   '110000' => '250.3', '110001' => '254.1',);


our %DCSCODES = ('0000000' => '023', '0000001' => '025', '0000010' => '026', '0000011' => '031',
                   '0000100' => '032', '0000101' => '036', '0000110' => '043', '0000111' => '047',
                   '0001000' => '051', '0001001' => '053', '0001010' => '054', '0001011' => '065',
                   '0001100' => '071', '0001101' => '072', '0001110' => '073', '0001111' => '074',
                   '0010000' => '114', '0010001' => '115', '0010010' => '116', '0010011' => '122',
                   '0010100' => '125', '0010101' => '131', '0010110' => '132', '0010111' => '134',
                   '0011000' => '143', '0011001' => '145', '0011010' => '152', '0011011' => '155',
                   '0011100' => '156', '0011101' => '162', '0011110' => '165', '0011111' => '172',
                   '0100000' => '174', '0100001' => '205', '0100010' => '212', '0100011' => '223',
                   '0100100' => '225', '0100101' => '226', '0100110' => '243', '0100111' => '244',
                   '0101000' => '245', '0101001' => '246', '0101010' => '251', '0101011' => '252',
                   '0101100' => '255', '0101101' => '261', '0101110' => '263', '0101111' => '265',
                   '0110000' => '266', '0110001' => '271', '0110010' => '274', '0110011' => '306',
		   '0110100' => '311', '0110101' => '315', '0110110' => '325', '0110111' => '331',
		   '0111000' => '332', '0111001' => '343', '0111010' => '346', '0111011' => '351',
		   '0111100' => '356', '0111101' => '364', '0111110' => '365', '0111111' => '371',
		   '1000000' => '411', '1000001' => '412', '1000010' => '413', '1000011' => '423',
		   '1000100' => '431', '1000101' => '432', '1000110' => '445', '1000111' => '446',
		   '1001000' => '452', '1001001' => '454', '1001010' => '455', '1001011' => '462',
		   '1001100' => '464', '1001101' => '465', '1001110' => '466', '1001111' => '503',
		   '1010000' => '506', '1010001' => '516', '1010010' => '523', '1010011' => '526',
		   '1010100' => '532', '1010101' => '546', '1010110' => '565', '1010111' => '606',
		   '1011000' => '612', '1011001' => '624', '1011010' => '627', '1011011' => '631',
		   '1011100' => '632', '1011101' => '654', '1011110' => '662', '1011111' => '664',
		   '1100000' => '703', '1100001' => '712', '1100010' => '723', '1100011' => '731',
		   '1100100' => '732', '1100101' => '734', '1100110' => '743', '1100111' => '754',);


our %TXPWR = (HIGH => '00', LOW3 => '01', LOW2 => '10', LOW1 => '11');

our %VFOBANDS = ('160M' => '0000', '75M' => '0001', '40M' => '0010', '30M' => '0011',
             '20M' => '0100', '17M' => '0101', '15M' => '0110', '12M' => '0111',
             '10M' => '1000', '6M' => '1001', 'FMBC' => '1010', 'AIR' => '1011',
             '2M' => '1100', '70CM' => '1101', 'PHAN' => '1110');


our %VFOABASE = ('160M' => '007D', '75M' => '0097', '40M' => '00B1', '30M' => '00CB',
             '20M' => '00E5', '17M' => '00FF', '15M' => '0119', '12M' => '0133',
             '10M' => '014D', '6M' => '0167', 'FMBC' => '0181', 'AIR' => '019B',
             '2M' => '01B5', '70CM' => '01CF', 'PHAN' => '01E9');

our %VFOBBASE = ('160M' => '0203', '75M' => '021D', '40M' => '0237', '30M' => '0251',
             '20M' => '026B', '17M' => '0285', '15M' => '029F', '12M' => '02B9',
             '10M' => '02D3', '6M' => '02ED', 'FMBC' => '0307', 'AIR' => '0321',
             '2M' => '033B', '70CM' => '0355', 'PHAN' => '036F');

our %HOMEBASE = ('HF' => '0389', '6M' => '03A3', '2M' => '03BD', 'UHF' => '03D7');

our %OPMODES =  (LSB => '00', USB => '01', CW => '02',
             CWR => '03', AM => '04', FM => '08',
             DIG => '0A', PKT => '0C', FMN => '88',
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
        if($verbose){
                printf "\n%-11s %-11s\n", 'FLAG','VALUE';
                print "_________________";
                printf "\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'DEBUG', "$debug", 'VERBOSE', "$verbose", 'WRITE', "$writeallow", 'WARNED', "$agreewithwarning";
                    }
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


#### Add a HEX VALUE AND RETURN MSB/LSB
sub hexAdder {
        my $self  = shift;
        my $offset = shift;
	my $base = shift;
        if ($debug){print "\n(hexAdder:DEBUG) - RECEIVED BASE [$base] AND OFFSET [$offset]\n";}
        my $basehex = join("",'0x',"$base");
        if ($debug){print "\n(hexAdder:DEBUG) - CONVERT  BASE [$basehex]\n";}
        $basehex = hex($basehex);
        if ($debug){print "\n(hexAdder:DEBUG) - OCT   BASEHEX [$basehex]\n";}
        my $startaddress = sprintf("0%X",$basehex + $offset);
        if(length($startaddress) < 4) {$startaddress = join("",'0',"$startaddress");}
        if ($debug){print "\n(hexAdder:DEBUG) - ADDED OFFSET [$startaddress]\n";}
        if ($debug){print "\n(hexAdder:DEBUG) - PRODUCED [$startaddress]\n\n";}
return $startaddress;
	     }

sub hexDiff {
        my $self  = shift;
        my $ADDRESS1 = shift;
	my $ADDRESS2 = shift;
        if ($debug){print "\n(hexDiff:DEBUG) - RECEIVED HEX1 [$ADDRESS1] AND HEX2 [$ADDRESS2]\n";}
        if ($debug){print "\n(hexDiff:DEBUG) - COMPUTING DECIMAL DIFFERENCE\n";}
        $ADDRESS1 = hex($ADDRESS1);
	$ADDRESS2 = hex($ADDRESS2);
	my $difference = $ADDRESS2 - $ADDRESS1;
        if ($debug){print "\n(hexDiff:DEBUG) - GOT $difference\n\n";}
return $difference;
             }


#### Send a CAT command and set the return byte size
sub sendCat {
	my $self  = shift;
	my ($data1, $data2, $data3, $data4, $command, $outputsize) = @_;
	if ($debug){print "\n(sendCat:DEBUG) - DATA OUT ------> $data1 $data2 $data3 $data4 $command\n";}
	my $data = join("","$data1","$data2","$data3","$data4","$command");
        if ($debug){print "\n(sendCat:DEBUG) - BUILT PACKET --> $data\n";}
	$data = pack( 'H[10]', "$data" );
	$self->{'port'}->write($data);
	$catoutput = $self->{'port'}->read($outputsize);
	$catoutput = unpack("H*", $catoutput);
	if ($debug) {print "\n(sendCat:DEBUG) - DATA IN <------- $catoutput\n\n";}
return $catoutput;
            }

#### Decodes eeprom values from a given address and stips off second byte
sub eepromDecode {
	my $self  = shift;
	my $address = shift;
	if ($debug){print "\n(eepromDecode:DEBUG) - READING FROM ------> [$address]\n";}
        my $data = join("","$address",'0000BB');
        if ($debug){print "\n(eepromDecode:DEBUG) - PACKET BUILT ------> [$data]\n";}
	$data = pack( 'H[10]', "$data" );
	$self->{'port'}->write($data);
	$output = $self->{'port'}->read(2);
	$output = unpack("H*", substr($output,0,1));
        if ($debug){print "\n(eepromDecode:DEBUG) - OUTPUT HEX  -------> [$output]\n";}
	$output = hex2bin($output);
        if ($debug){print "\n(eepromDecode:DEBUG) - OUTPUT BIN  -------> [$output]\n\n";}
return $output;
                 }


#### Decodes eeprom values from a given address and stips off second byte
sub eepromDecodenext {
        my $self  = shift;
	my $address = shift;
        if ($debug){print "\n(eepromDecodenext:DEBUG) - READING FROM from -> [$address]\n";}
        my $data = join("","$address",'0000BB');
	if ($debug){print "\n(eepromDecodenext:DEBUG) - PACKET BUILT ------> [$data]\n";}
	$data = pack( 'H[10]', "$data" );
	$self->{'port'}->write($data);
        $output = $self->{'port'}->read(2);
        $output = unpack("H*", substr($output,1,1));
	if ($debug){print "\n(eepromDecodenext:DEBUG) - OUTPUT HEX --------> [$output]\n\n";}
return $output;
                     }


#### Writes data to the eeprom MSB,LSB,BIT# and VALUE,  REWRITES NEXT MEMORY ADDRESS
sub writeEeprom {
        my $self=shift;
        my $address = shift;
	my ($writestatus) = @_;
	my $BIT=shift;
	my $VALUE=shift;
	my $NEWHEX1;
	my $NEWHEX2;
	if ($writeallow != '1' and $agreewithwarning != '1') {
		if($debug || $verbose == '2'){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
		if ($verbose == '1'){ print "Writing to EEPROM disabled and must be enabled before use....\n";}
		$writestatus = "Write Disabled";
return $writestatus;
			  }
	if ($debug){print "\n(writeEeprom:DEBUG) - OUTPUT FROM [$address]\n";}
        my $data = join("","$address",'0000BB');
        if ($debug){print "\n(writeEeprom:DEBUG) - PACKET BUILT ------> [$data]\n";}
        $data = pack( 'H[10]', "$data" );
        $self->{'port'}->write($data);
	my $output = $self->{'port'}->read(2);
	my $BYTE1 = unpack("H*", substr($output,0,1));
	my $BYTE2 = unpack("H*", substr($output,1,1));
	my $OLDBYTE1 = $BYTE1;
	my $OLDBYTE2 = $BYTE2;
	if ($debug){print "\n(writeEeprom:DEBUG) - BYTE1 ($BYTE1) BYTE2 ($BYTE2) from [$address]\n";}
	$BYTE1 = hex2bin($BYTE1);
	my $HEX1 = sprintf("%X", oct( "0b$BYTE1" ) );
	if ($debug){print "\n(writeEeprom:DEBUG) - BYTE1 BINARY IS [$BYTE1]\n";}
	if ($debug){print "\n(writeEeprom:DEBUG) - CHANGING BIT($BIT) to ($VALUE)\n";}
	substr($BYTE1, $BIT, 1) = "$VALUE";
	if ($debug){print "\n(writeEeprom:DEBUG) - BYTE1: BINARY IS [$BYTE1] AFTER CHANGE\n";}
	$NEWHEX1 = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($debug){print "\n(writeEeprom:DEBUG) - CHECKING IF [$NEWHEX1] needs padding\n";}
        if (length($NEWHEX1) < 2) {
                   $NEWHEX1 = join("",'0', "$NEWHEX1");
                if ($debug){print "\n(writeEeprom:DEBUG) - Padded to [$NEWHEX1]\n";}
                                }
        else {if ($debug){print "\n(writeEeprom:DEBUG) - No padding of [$NEWHEX1] needed\n";}}
	if ($debug){print "\n(writeEeprom:DEBUG) - BYTE1 ($NEWHEX1) BYTE2 ($BYTE2) to [$address]\n";}
	if ($debug){print "\n(writeEeprom:DEBUG) - WRITING  ----------> ($NEWHEX1) ($BYTE2)\n";}
        my $data2 = join("","$address","$NEWHEX1","$BYTE2",'BC');
	if ($debug){print "\n(writeEeprom:DEBUG) - PACKET BUILT ------> [$data2]\n";}
	$data2 = pack( 'H[10]', "$data2" );
        $self->{'port'}->write($data2);
        $output = $self->{'port'}->read(2);
	if ($debug){print "\n(writeEeprom:DEBUG) - VALUES WRITTEN, CHECKING...\n";}
        $self->{'port'}->write($data);
        my $output2 = $self->{'port'}->read(2);
        $BYTE1 = unpack("H*", substr($output2,0,1));
        $BYTE2 = unpack("H*", substr($output2,1,1));
        if ($debug){print "\n(writeEeprom:DEBUG) - SHOULD BE: ($NEWHEX1) ($OLDBYTE2)\n";}
        if ($debug){print "\n(writeEeprom:DEBUG) - IS: -----> ($BYTE1) ($BYTE2)\n";}
	if ($output2 == $output) {
		$writestatus = "OK";
		if($debug){print "\n(writeEeprom:DEBUG) - VALUES MATCH!!!\n\n";}
		          }
        else {
		$writestatus = "1";
		if($debug){print "\n(writeEeprom:DEBUG) - NO MATCH!!!\n\n";}
			  }
return $writestatus;
               }


#### Writes an entire byte of data to the eeprom, MSB LSB VALUE
sub writeBlock {
        my $self=shift;
        my ($writestatus) = @_;
	my $address=shift;
        my $VALUE=shift;

        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose == '2'){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
                if ($verbose == '1'){ print "Writing to EEPROM disabled and must be enabled before use....\n";}
                $writestatus = "Write Disabled";
return $writestatus;
				                             }

if ($debug){print "\n(writeBlock:DEBUG) - OUTPUT FROM [$address]\n";}
        my $data = join("","$address",'0000BB');
        if ($debug){print "\n(writeBlock:DEBUG) - PACKET BUILT ------> [$data]\n";}
        $data = pack( 'H[10]', "$data" );
        $self->{'port'}->write($data);
        my $output = $self->{'port'}->read(2);
        my $BYTE2 = unpack("H*", substr($output,1,1));
        my $OLDBYTE2 = $BYTE2;
        if ($debug){print "\n(writeBlock:DEBUG) - BYTE2 ($BYTE2) from [$address]\n";}
        if ($debug){print "\n(writeBlock:DEBUG) - BYTE1 ($VALUE) BYTE2 ($BYTE2) to   [$address]\n";}
	if ($debug){print "\n(writeBlock:DEBUG) - CHECKING IF [$VALUE] needs padding\n";}
	if (length($VALUE) < 2) {
		   $VALUE = join("",'0', "$VALUE");
		if ($debug){print "\n(writeBlock:DEBUG) - Padded to [$VALUE]\n";}
			        }
	else {if ($debug){print "\n(writeBlock:DEBUG) - No padding of [$VALUE] needed\n";}}
        if ($debug){print "\n(writeBlock:DEBUG) - WRITING  ----------> [$VALUE] [$BYTE2]\n";}
        my $data2 = join("","$address","$VALUE","$BYTE2",'BC');
        if ($debug){print "\n(writeBlock:DEBUG) - PACKET BUILT ------> [$data2]\n";}
        $data2 = pack( 'H[10]', "$data2" );
        $self->{'port'}->write($data2);
	$output = $self->{'port'}->read(2);
        if ($debug){print "\n(writeBlock:DEBUG) - VALUES WRITTEN, CHECKING...\n";}
        $self->{'port'}->write($data);
        my $output2 = $self->{'port'}->read(2);
        my $BYTE1 = unpack("H*", substr($output2,0,1));
        $BYTE2 = unpack("H*", substr($output2,1,1));
        if ($debug){print "\n(writeBlock:DEBUG) - SHOULD BE: ($VALUE) ($OLDBYTE2)\n";}
        if ($debug){print "\n(writeBlock:DEBUG) - IS: -----> ($BYTE1) ($BYTE2)\n";}
        if ($output2 == $output) {
                $writestatus = "OK";
                if($debug){print "\n(writeBlock:DEBUG) - VALUES MATCH!!!\n\n";}
                          }
        else {
                $writestatus = "1";
                if($debug){print "\n(writeBlock:DEBUG) - NO MATCH!!!\n\n";}
                          }
return $writestatus;
               }



#### Restores eprom memory address to pre written default value in case there was an error

sub restoreEeprom {
        my $self=shift;
	my $area=shift;
        my ($writestatus,$test,$restorevalue,$address) = @_;
        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose == '2'){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
                if ($verbose == '1'){ print "Writing to EEPROM disabled and must be enabled before use....\n";}
                $writestatus = "Write Disabled";
return $writestatus;
                          }



	if (($area ne '0057') && ($area ne '005F') && ($area ne '0062') && ($area ne '007B') && ($area ne '007A') && ($area ne '0079') && ($area ne '005D') && ($area ne '0058') && ($area ne '0059')){
		if($debug || $verbose){print "Address ($area) not supported for restore...\n";}
		$writestatus = "Invalid memory address ($area)";
return $writestatus;
			  }


        if ($area eq '0057'){
                $restorevalue = '00';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x57\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'AGC','AUTO', 'DSP','OFF', 'PBT','OFF', 'NB', 'OFF', 'LOCK','OFF', 'FASTTUNE','OFF';
                             }
                          }


        if ($area eq '0058'){
		$restorevalue = '00';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x58\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'PWR METER','PWR', 'CW PADDLE','NORMAL', 'KEYER','OFF', 'BK', 'OFF', 'VLT','OFF', 'VOX','OFF';
                             }
                          }


        if ($area eq '0059'){
                $restorevalue = '4C';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x59\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n\n", 'VFO A','2M', 'VFO B','20M';
                             }
                          }


        if ($area eq '005D'){
                $restorevalue = '42';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x5D\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'Resume Scan','OFF', 'PKT Rate','1200', 'Scope','CONT', 'CW-ID', 'OFF', 'Main STEP','FINE', 'ARTS','RANGE';
                             }
                          }

        if ($area eq '005F'){
		$restorevalue = 'E5';
		if ($verbose){
			print "\nDEFAULTS LOADED FOR 0x5F\n";
			print "________________________\n";
			printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'CW Weight','1:3', '430 ARS','ON', '144 ARS','ON', 'SQL-RFG', 'SQUELCH';
			     }			
			  } 

        if ($area eq '0062'){
		$restorevalue = '48';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x62\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n\n", 'CW Speed','12wpm', 'Chargetime','8hrs';
                             }
		  	  }

        if ($area eq '0079'){
                $restorevalue = '03';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x79\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'TX Power','LOW1', 'PRI','OFF', 'DUAL-WATCH', 'OFF', 'SCAN', 'OFF', 'ARTS', 'OFF';
                             }
			  }

        if ($area eq '007A'){
		$restorevalue = '0F';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x7A\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n\n", 'Antennas','All Rear except VHF and UHF', 'SPL','OFF';
                             }
			  }
        if ($area eq '007B'){
		$restorevalue = '08';
                if ($verbose){
                        print "\nDEFAULTS LOADED FOR 0x7B\n";
                        print "________________________\n";
                        printf "%-11s %-11s\n%-11s %-11s\n\n", 'Chargetime','8hrs', 'Charger','OFF';
                             }
			  }

        $writestatus = $self->writeBlock("$area","$restorevalue");


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
	$self->setVerbose(0);
	$output=$self->getLock();
	$self->setVerbose(1);
        if ($output eq $lock) {
                if($verbose){print "\nLock is already set to $lock\n\n"; }
return 1;
                              }

        if ($lock ne 'ON' && $lock ne 'OFF') {
                if($verbose){print "\nChoose valid option: ON/OFF\n\n"; }
return 1;
                                             }
	if ($lock eq 'ON') {$data = "00";}
	if ($lock eq 'OFF') {$data = "80";}
	if ($data){$catoutput = $self->sendCat('00','00','00','00',"$data",1);}
	else {$catoutput = "$syntaxerr";}
	if ($verbose){
		print "Set Lock ($lock) Sucessfull.\n" if ($catoutput eq '00');
		print "Set Lock ($lock) Failed.\n" if ($catoutput eq 'f0');
           	     }
return $catoutput;
            }

#### ENABLE/DISABLE PTT VIA CAT
sub setPtt {
        my ($data) = @_;
	my $self=shift;
	my $ptt = shift;
	$data = undef;

        if ($ptt ne 'ON' && $ptt ne 'OFF') {
                if($verbose){print "\nChoose valid option: ON/OFF\n\n"; }
return 1;
                                           }

	if ($ptt eq 'ON') {$data = "08";}
	if ($ptt eq 'OFF') {$data = "88";}
	if ($data){$catoutput = $self->sendCat('00','00','00','00',"$data",1);}
	else {$catoutput = "$syntaxerr";}
	if ($verbose){
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

        $self->setVerbose(0);
        $output=$self->getFrequency();
        $self->setVerbose(1);
        if ($output eq $newfrequency) {
                if($verbose){print "\nFrequency is already set to $newfrequency\n\n"; }
return 1;
                                      }

        if ($newfrequency!~ /\D/ && length($newfrequency)=='8') {
		$f1 = substr($newfrequency, 0,2);
		$f2 = substr($newfrequency, 2,2);
		$f3 = substr($newfrequency, 4,2);
		$f4 = substr($newfrequency, 6,2);
							        }
	else {
		$badf = $newfrequency;
		$newfrequency = undef;
return 1;
	     }
	$catoutput = $self->sendCat("$f1","$f2","$f3","$f4",'01',1);
	if ($verbose){
		print "Set Frequency ($newfrequency) Sucessfull.\n" if ($catoutput eq '00');
		print "Set Frequency ($newfrequency) Failed. $newfrequency invalid or out of range\?\n" if ($catoutput eq 'f0');
            	     }
return $catoutput;
                 }

#### SET MODE VIA CAT
sub setMode {
	my $self=shift;
	my $newmode = shift;
        $self->setVerbose(0);
        $output=$self->getMode();
        $self->setVerbose(1);
        if ($output eq $newmode) {
                if($verbose){print "\nMode is already set to $newmode\n\n"; }
return 1;
                                 }

        my %newhash = reverse %OPMODES;
        my ($mode) = grep { $newhash{$_} eq $newmode } keys %newhash;
        if ($mode eq'') {
                if($verbose){print "\nChoose valid mode: ON/OFF\n\n"; }
return 1;
                        }
	$catoutput = $self->sendCat("$mode","00","00","00",'07',1);
	if ($verbose){
		print "Set Mode ($newmode) Sucessfull.\n" if ($catoutput eq '00');
		print "Set Mode ($newmode) Failed.\n" if (! $mode || $catoutput ne '00');
            	     }
return $catoutput;
         }

#### ENABLE/DISABLE CLARIFIER VIA CAT
sub setClarifier {
	my ($data) = @_;
	my $self=shift;
	my $clarifier = shift;
	$data = undef;

        if ($clarifier ne 'ON' && $clarifier ne 'OFF') {
                if($verbose){print "\nChoose valid option: ON/OFF\n\n"; }
return 1;
                                                       }

	if ($clarifier eq 'ON') {$data = "05";}
	if ($clarifier eq 'OFF') {$data = "85";}
        $catoutput = $self->sendCat('00','00','00','00',"$data",1);
        if ($verbose){
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
        if ($polarity ne 'POS' && $polarity ne 'NEG') {
                if($verbose){print "\nChoose valid option: POS/NEG\n\n"; }
return 1;
                                                      }
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
			$catoutput = $self->sendCat("$p",'00',"$f1","$f2",'f5',1)}};

        if ($verbose){
                print "Set Clarifier Frequency ($polarity:$badf) Failed. Must contain 4 digits 0-9.\n" if (! $frequency);
		print "Set Clarifier Frequency ($polarity:$frequency) Sucessfull.\n" if ($catoutput eq '00');
		print "Set Clarifier Frequency ($polarity:$frequency) Failed. $frequency out of range\?\n" if ($catoutput eq 'f0');
                     }
return $catoutput;
                     }

#### TOGGLE VFO A/B VIA CAT
sub vfoToggle {
	my $self=shift;
	$catoutput = $self->sendCat('00','00','00','00','81',1);
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

        if ($split ne 'ON' && $split ne 'OFF') {
                if($verbose){print "\nChoose valid option: ON/OFF\n\n"; }
return 1;
                                               }
	if ($split eq 'ON') {$data = "02";}
	if ($split eq 'OFF') {$data = "82";}


	$catoutput = $self->sendCat('00','00','00','00',"$data",1);
        if ($verbose){
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

        if ($offsetmode ne 'POS' && $offsetmode ne 'NEG' && $offsetmode ne 'SIMPLEX') {
                if($verbose){print "\nChoose valid option: POS/NEG/SIMPLEX\n\n"; }
return 1;
                                                                                      }

	if ($offsetmode eq 'POS'){$datablock = '49';}
	if ($offsetmode eq 'NEG') {$datablock = '09';}
	if ($offsetmode eq 'SIMPLEX') {$datablock = '89';}
	$catoutput = $self->sendCat("$datablock",'00','00','00','09',1);
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
             }
	$catoutput = $self->sendCat("$f1","$f2","$f3","$f4",'F9',1);
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

        if ($ctcssdcs ne 'DCS' && $ctcssdcs ne 'CTCSS' && $ctcssdcs ne 'ENCODER' && $ctcssdcs ne 'OFF') {
                if($verbose){print "\nChoose valid option: DCS/CTCSS/ENCODER/OFF\n\n"; }
return 1;
                                                                                                        }

	if ($ctcssdcs eq 'DCS'){$data = "0A";}
	if ($ctcssdcs eq 'CTCSS'){$data = "2A";}
	if ($ctcssdcs eq 'ENCODER'){$data = "4A";}
	if ($ctcssdcs eq 'OFF'){$data = "8A";}
        $catoutput = $self->sendCat("$data",'00','00','00','0A',1);
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
return 1;
	      }
	if($tonefreq){$catoutput = $self->sendCat("$f1","$f2",'00','00','0B',1);}
        if ($verbose){
                print "Set CTCSS Tone ($badf) Failed. Must contain 4 digits 0-9.\n" if (! $tonefreq);
                print "Set CTCSS Tone ($tonefreq) Sucessfull.\n" if ($catoutput eq '00');

	if ($catoutput eq 'f0'){
		print "Set CTCSS ($tonefreq) Failed. $tonefreq is not a valid tone frequency\.\n\n";
		my $columns = 1;
		foreach my $tones (sort keys %CTCSSTONES) {
    		printf "%-15s %s",$CTCSSTONES{$tones};
		$columns++;
		if ($columns == 7){print "\n\n"; $columns = 1;}
 			  			          }
		print "\n\n";	       
				}
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
return 1;
              }
	if($code){$catoutput = $self->sendCat("$f1","$f2",'00','00','0C',1);}
        if ($verbose){
                print "Set DCS Code ($badf) Failed. Must contain 4 digits 0-9.\n" if (! $code);
                print "Set DCS Code ($code) Sucessfull.\n" if ($catoutput eq '00');
	if ($catoutput eq 'f0') {
                print "Set DCS Code ($code) Failed. $code is not a valid DCS Code\.\n\n";
		my $columns = 1;
                foreach my $codes (sort keys %DCSCODES) {
                printf "%-15s %s",$DCSCODES{$codes};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                          }
                print "\n\n";

				}
                     }
return $catoutput;
                 }

#### GET MULTIPLE VALUES OF RX STATUS RETURN AS variables OR hash
sub getRxstatus {
        my ($match,$desc) = @_;
        my $self=shift;
        my $option = shift;
	if (!$option){$option = 'HASH';} 
        $catoutput = $self->sendCat('00','00','00','00','E7',1);
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
                print "\nReceive status:\n\n";
                printf "%-18s %-11s\n", 'FUNCTION','VALUE';
                print "________________________";
                printf "\n%-18s %-11s\n%-18s %-11s\n%-18s %-11s\n%-18s %-11s\n\n", 'Squelch', "$squelch", 'S-METER', "$smeter \/ $smeterlin", 'Tone Match', "$match", 'Descriminator', "$desc";
		      }
	if ($option eq'VARIABLES'){
return ("$squelch","$smeter","$smeterlin" ,"$match", "$desc");
				  }
        if ($option eq 'HASH') {
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
        if (!$option){$option = 'HASH';}
        $catoutput = $self->sendCat('00','00','00','00','F7',1);
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
               print "\nTransmit status:\n\n";
                printf "%-18s %-11s\n", 'FUNCTION','VALUE';
                print "________________________";
                printf "\n%-18s %-11s\n%-18s %-11s\n%-18s %-11s\n%-18s %-11s\n\n", 'Power Meter', "$pometer", 'PTT', "$ptt", 'High SWR', "$highswr", 'Split', "$split";
                      }
        if ($option eq'VARIABLES'){
return ("$ptt","$pometer","$highswr" ,"$split");
                                  }
        if ($option eq 'HASH') {
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
	$catoutput = $self->sendCat('00','00','00','00','03',5);
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
	$catoutput = $self->sendCat('00','00','00','00','03',5);
	$currentmode = substr($catoutput,8,2);
	my ($mode) = grep { $OPMODES{$_} eq $currentmode } keys %OPMODES;
        if ($verbose){
                print "Mode is $mode\n";
                     }
return $mode;
            }

#### SETS RADIO POWER ON OR OFF VIA CAT
sub setPower {
        my ($data) = @_;
	my $self=shift;
	my $powerset = shift;
	$data = undef;
        if ($powerset ne 'ON' && $powerset ne 'OFF') {
                if($verbose){print "\nChoose valid option: ON/OFF\n\n"; }
return 1;
                                                     }
		    

	if ($powerset eq 'ON'){$data = "0F";}
	if ($powerset eq 'OFF') {$data = "8F";}
	$self->sendCat('00','00','00','00','00',1);
	$catoutput = $self->sendCat('00','00','00','00',"$data",1);
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
        my ($times,$valuehex) = @_;
        my $self=shift;
	my $address1 =shift;
	my $address2 = shift;
	my $base = $address1;
	if (!$address2) {$address2 = $address1;}

        if ($verbose){
		if (!$address1) {
                print "Get EEPROM ($address1 $address2) Failed. Must contain  hex value 0-9 a-f. i.e. [005F] or  [005F 006A] for a range\n"; 
return 1;
			        }
                 


		$times=$self->hexDiff("$address1","$address2");
                if ($times < 0) {
                print "The Secondary value [$address2] must be greater than the first [$address1]";
return 1;
                                }
                     }


                print "\n";
                printf "%-11s %-15s %-11s %-11s\n", 'ADDRESS', 'BINARY', 'DECIMAL', 'VALUE';
                print "___________________________________________________\n";

		$times++;
		my $cycles = 0;


	do {
		my $valuebin = $self->eepromDecode("$address1");
                my $valuehex = sprintf("%X", oct( "0b$valuebin" ) );
                my $valuedec = hex($valuehex);
                printf "%-11s %-15s %-11s %-11s\n", "$address1", "$valuebin", "$valuedec", "$valuehex";
		$cycles++;
                $address1 = $self->hexAdder("$cycles","$base");

  	   }
	        while ($cycles < $times);

		print "\n";
return $valuehex;
              }

# 0-3 ################################# GET EEPROM CHECKSUM
###################################### READ ADDRESS 0X0 AND 0X3
sub getChecksum {
        my ($checksumhex0,$checksumhex1,$checksumhex2,$checksumhex3) = @_;
        my $self=shift;
        my $type=shift;
        my $output0 = $self->eepromDecode('0000');
        my $output1 = $self->eepromDecode('0001');
        my $output2 = $self->eepromDecode('0002');
        my $output3 = $self->eepromDecode('0003');
        $checksumhex0 = sprintf("%X", oct( "0b$output0" ) );
        $checksumhex1 = sprintf("%X", oct( "0b$output1" ) );
        $checksumhex2 = sprintf("%X", oct( "0b$output2" ) );
        $checksumhex3 = sprintf("%X", oct( "0b$output3" ) );
        my $configoutput = "[$checksumhex0][$checksumhex1][$checksumhex2][$checksumhex3]";
        if($verbose){
                print "\nCHECKSUM VALUES ARE:\n\n";
                printf "%-11s %-11s\n", 'ADDRESS','HEX';
                print "_______________";
                printf "\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", '0x00', "$checksumhex0", '0x01', "$checksumhex1", '0x02', "$checksumhex2", '0x03', "$checksumhex3";
                    }
return $configoutput;
           }

# 4-5 ################################# GET RADIO VERSION VIA EEPROMDECODE
###################################### READ ADDRESS 0X4 AND 0X5
sub getConfig {
        my ($confighex4,$confighex5,$output4,$output5) = @_;
        my $self=shift;
	my $type=shift;
        $output4 = $self->eepromDecode('0004');
	$confighex4 = sprintf("%x", oct( "0b$output4" ) );
        $output5 = $self->eepromDecode('0005');
        $confighex5 = sprintf("%x", oct( "0b$output5" ) );
	my $configoutput = "[$confighex4][$confighex5]";
        $out = "\nHardware Jumpers created value of\n0x04[$output4]($confighex4)\n0x05[$output5]($confighex5)\n\n";
        if($verbose){
                print "\nHardware Jumpers created value of\n\n";
		printf "%-11s %-11s %-15s\n", 'ADDRESS','BINARY','HEX';
		print "___________________________"; 
                printf "\n%-11s %-11s %-15s\n%-11s %-11s %-15s\n\n", '0x04', "$output4", "$confighex4", '0x05', "$output5", "$confighex5";
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
	if (!$option){$option = 'CONSOLE';}
	my $block = 1;
	my $startaddress = "07";
	my $digestdata = undef;
	my $memoryaddress;

	if ($option eq 'CONSOLE') {
		if ($verbose){
		print "\n";
		printf "%-11s %-15s %-11s %-11s\n", 'ADDRESS', 'BINARY', 'DECIMAL', 'VALUE';
		print "___________________________________________________\n";
			     }
	                          }


        if ($verbose && $option eq 'DIGEST'){
                print "Generated an MD5 hash from software calibration values ";
                     }

        if ($option eq 'FILE'){
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


	if ($option eq 'DIGEST') {

        do {
                $memoryaddress = sprintf("%x",$startaddress);
                my $size = length($memoryaddress);
                if ($size < 2){$memoryaddress = join("",'0',"$memoryaddress");}
		$memoryaddress = join("",'00',"$memoryaddress");
                my $valuebin = $self->eepromDecode("$memoryaddress");
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



	else {

	do {

		$memoryaddress = sprintf("%x",$startaddress);
		my $size = length($memoryaddress);
		if ($size < 2){$memoryaddress = join("",'0',"$memoryaddress");}	
                $memoryaddress = join("",'00',"$memoryaddress");
		my $valuebin = $self->eepromDecode("$memoryaddress");
		my $valuehex = sprintf("%x", oct( "0b$valuebin" ) );
		my $valuedec = hex($valuehex);
	if ($option eq 'CONSOLE' || $verbose) {
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
	$output = $self->eepromDecode('0055');
	my @block55 = split("",$output);
	if ($block55[7] == '0') {$vfo = "A";}
	if ($block55[7] == '1') {$vfo = "B";}
        if($verbose){
                print "VFO is $vfo\n";
                    }
return $vfo;
           }

sub getHome {
        my $self=shift;
        $output = $self->eepromDecode('0055');
	my @block55 = split("",$output);
	if ($block55[3] == '1') {$home = "Y";}
	if ($block55[3] == '0') {$home = "N";}
        if($verbose){
		if($home eq'Y'){print "At Home Frequency.\n";}
		if($home eq 'N'){print "Not at Home Frequency\n";}
                    }
return $home;
            }

sub getTuner {
	my $self=shift;
	$output = $self->eepromDecode('0055');
	my @block55 = split("",$output);
	if ($block55[0] == '1') {$tuneselect = "VFO";}
	if ($block55[0] == '0') {$tuneselect = "MEMORY";}
        if($verbose){
                print "Tuner is $tuneselect\n";
                    }
return $tuneselect;
             }

# 57 ################################# GET AGC MODE, NOISE BLOCK, FASTTUNE ,PASSBAND Tuning, DSP AND LOCK ######
###################################### READ BITS 0-1 , 2, 4 ,5 AND 6 FROM 0X57

sub getAgc {
	my $self=shift;
	$output = $self->eepromDecode('0057');
	my $agcvalue = substr($output,6,2);
	my ($agc) = grep { $AGCMODES{$_} eq $agcvalue } keys %AGCMODES;
        if($verbose){
                print "AGC is $agc\n";
                    }
return $agc;
           }


sub getDsp {
        my $self=shift;
        $output = $self->eepromDecode('0057');
        my @block55 = split("",$output);
        if ($block55[5] == '0') {$dsp = "OFF";}
        if ($block55[5] == '1') {$dsp = "ON";}
        if($verbose){
                print "DSP is $dsp\n";
                    }
return $dsp;
           }

sub getPbt {
        my $self=shift;
	my $pbt;
        $output = $self->eepromDecode('0057');
        my @block55 = split("",$output);
        if ($block55[3] == '0') {$pbt = "OFF";}
        if ($block55[3] == '1') {$pbt = "ON";}
        if($verbose){
                print "Passband Tuning is $pbt\n";
                    }
return $pbt;
           }


sub getNb    {
	my $self=shift;
	$output = $self->eepromDecode('0057');
	my @block55 = split("",$output);
	if ($block55[2] == '0') {$nb = "OFF";}
	if ($block55[2] == '1') {$nb = "ON";}
        if($verbose){
                print "Noise Blocker is $nb\n";
                    }
return $nb;
             }

sub getLock    {
	my $self=shift;
	$output = $self->eepromDecode('0057');
	my @block55 = split("",$output);
	if ($block55[1] == '1') {$lock = "OFF";}
	if ($block55[1] == '0') {$lock = "ON";}
        if($verbose){
                print "Lock is $lock\n";
                    }
return $lock;
                }

sub getFasttuning {
        my $self=shift;
        $output = $self->eepromDecode('0057');
        my @block55 = split("",$output);
        if ($block55[0] == '1') {$fasttuning = "OFF";}
        if ($block55[0] == '0') {$fasttuning = "ON";}
        if($verbose){
                print "Fast Tuning is $fasttuning\n";
                    }
return $fasttuning;
                  }




# 58 ################################# GET VOX ######
###################################### READ BIT 7 FROM 0X58

sub getVox {
        my ($vox) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0058');
        my @block55 = split("",$output);
        if ($block55[0] == '0') {$vox = "OFF";}
        if ($block55[0] == '1') {$vox = "ON";}
        if($verbose){
                print "VOX is $vox\n";
                    }
return $vox;
           }


# 59 ################################# GET VFO BANDS ######
###################################### READ  ALL BITS FROM 0X59

sub getVfoband {
        my ($vfoband, $vfobandvalue) = @_;
        my $self=shift;
        my $value=shift;

        if ($value ne 'A' && $value ne 'B'){
                if($verbose){print "Value invalid: Choose A/B\n\n"; }
return 1;
                                                                    }
        $output = $self->eepromDecode('0059');
	if ($value eq 'A'){$vfobandvalue = substr($output,4,4);}
	if ($value eq 'B'){$vfobandvalue = substr($output,0,4);}
        ($vfoband) = grep { $VFOBANDS{$_} eq $vfobandvalue } keys %VFOBANDS;
        if($verbose == '1'){
                print "VFO Band is $vfoband\n";
                           }
return $vfoband;
               }


# 5d ################################# GET ARTS BEEP MODE ######
###################################### READ BIT 6-7 FROM 0X5d

sub getArtsmode {
        my ($artsmode) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005D');
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

sub getRfknob {
        my ($sqlbit,$value) = @_;
	my $self=shift;
        $output = $self->eepromDecode('005F');
	$sqlbit = substr($output,0,1);
        if($sqlbit == '0'){$value = 'RFGAIN';}
        else {$value = 'SQUELCH';}
        if($verbose){
                print "RF-KNOB is set to $value\n";
                    }
return $value; 
           }



# 79 ################################# GET TX POWER AND ARTS ######
###################################### READ BIT 0-1 AND 7 FROM 0X79

sub getTxpower {
	my $self=shift;
	$output = $self->eepromDecode('0079');
	my $txpower = substr($output,6,2);
	($txpow) = grep { $TXPWR{$_} eq $txpower } keys %TXPWR;
        if($verbose){
                print "Tx power is $txpow\n";
                    }
return $txpow;
               }

sub getArts {
        my ($artsis) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0079');
        my $arts = substr($output,0,1);
	if ($arts == '0'){$artsis = 'OFF'};
        if ($arts == '1'){$artsis = 'ON'};

        if($verbose){
                print "ARTS is $artsis\n";
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
        $output = $self->eepromDecode('007A');

        if ($value eq 'HF'){$antenna = substr($output,7,1);}
        if ($value eq '6M'){$antenna = substr($output,6,1);}
        if ($value eq 'FMBCB'){$antenna = substr($output,5,1);}
        if ($value eq 'AIR'){$antenna = substr($output,4,1);}
        if ($value eq 'VHF'){$antenna = substr($output,3,1);}
        if ($value eq 'UHF'){$antenna = substr($output,2,1);}


	if ($antenna == 0){$ant = 'FRONT';}
        if ($antenna == 1){$ant = 'BACK';}
	
	if ($value && $value ne 'ALL'){
        if($verbose){
                print "Antenna [$value] is set to $ant\n";
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
        $output = $self->eepromDecode('007B');
	my $test = substr($output,3,1);
	my $time = substr($output,4,4);
        my $timehex = sprintf("%X", oct( "0b$time" ) );
	$time = hex($timehex);

        if ($test == '0') {$charger = "OFF";}
        if ($test == '1') {$charger = "ON";}

	if ($charger eq 'OFF'){
        if($verbose){
                print "Charger is [$charger]: Timer configured for $time hours\n";
                    }
			      }

	        if ($charger eq 'ON'){
        if($verbose){
                print "Charging is [$charger]: Set for $time hours\n";
                    }
                                     }
return $charger;
           
	       }



# 7D - 388 ################################# GET VFO MEM INFO ######
###################################### 

sub readMemvfo {
        my ($testvfoband, $base, %baseaddress, $offset, $startaddress, $fmstep, $amstep, $ctcsstone, $dcscode) = @_;
        my $self=shift;
        my $vfo=shift;
        my $band=shift;
        my $value=shift;

        if ($vfo ne 'A' && $vfo ne 'B'){
                if($verbose){print "Value invalid: Choose A/B\n\n"; }
return 1;
                                                                    }


        my %newhash = reverse %VFOBANDS;
        ($testvfoband) = grep { $newhash{$_} eq $band } keys %newhash;
        if ($testvfoband eq'') {
                if($verbose){print "\nChoose valid Band : [160M/75M/40M/30M/20M/17M/15M/12M/10M/6M/2M/70CM/FMBC/AIR/PHAN]\n\n";}
return 1;
                               }

	if ($vfo eq 'A'){%baseaddress = reverse %VFOABASE;}
        if ($vfo eq 'B'){%baseaddress = reverse %VFOBBASE;}

($base) = grep { $baseaddress{$_} eq $band } keys %baseaddress;



if ($value eq 'MODE'){
	my $offset=0x00;
	my $address = $self->hexAdder("$offset","$base");
        my $mode;
        $output = $self->eepromDecode("$address");
        $output = substr($output,5,3);
        ($mode) = grep { $MEMMODES{$_} eq $output } keys %MEMMODES;
	if($verbose){print "VFO $vfo\[$band\] - MODE is $mode\n [this is broken]\n"};
return $mode;
                     }


if ($value eq 'NARFM'){
	my $offset=0x01;
        my $address = $self->hexAdder("$offset","$base");
        my $narfm;
        $output = $self->eepromDecode("$address");
        $output = substr($output,4,1);
        if ($output == '0') {$narfm = "OFF";}
        if ($output == '1') {$narfm = "ON";}
        if($verbose){print "VFO $vfo\[$band\] - NARROW FM is $narfm\n"};
return $narfm;
		      }

if ($value eq 'NARCWDIG'){
        my $offset=0x01;
        my $address = $self->hexAdder("$offset","$base");
        my $narcw;
        $output = $self->eepromDecode("$address");
        $output = substr($output,3,1);
        if ($output == '0') {$narcw = "OFF";}
        if ($output == '1') {$narcw = "ON";}
        if($verbose){print "VFO $vfo\[$band\] - NARROW CW/DIG is $narcw\n"};
return $narcw;
                      }


if ($value eq 'RPTOFFSET'){
        my $offset=0x01;
        my $address = $self->hexAdder("$offset","$base");
        my $rptoffset;
        $output = $self->eepromDecode("$address");
        $output = substr($output,0,2);
        if ($output == '00') {$rptoffset = "SIMPLEX";}
        if ($output == '01') {$rptoffset = "MINUS";}
        if ($output == '10') {$rptoffset = "PLUS";}
        if ($output == '11') {$rptoffset = "NON-STANDARD";}
        if($verbose){print "VFO $vfo\[$band\] - REPEATER OFFSET is $rptoffset\n"};
return $rptoffset;
                      }

if ($value eq 'TONEDCS'){
        my $offset=0x04;
        my $address = $self->hexAdder("$offset","$base");
        my $tonedcs;
        $output = $self->eepromDecode("$address");
        $output = substr($output,6,2);
        if ($output == '00') {$tonedcs = "OFF";}
        if ($output == '01') {$tonedcs = "TONE(TX)";}
        if ($output == '10') {$tonedcs = "TONE(TX) \+ TSQ";}
        if ($output == '11') {$tonedcs = "DCS";}
        if($verbose){print "VFO $vfo\[$band\] - TONE/DCS SELECT is $tonedcs\n"};
return $tonedcs;
                      }

if ($value eq 'ATT'){
        my $offset=0x02;
        my $address = $self->hexAdder("$offset","$base");
        my $att;
        $output = $self->eepromDecode("$address");
        $output = substr($output,3,1);
        if ($output == '0') {$att = "OFF";}
        if ($output == '1') {$att = "ON";}
        if($verbose){print "VFO $vfo\[$band\] - ATT is $att\n"};
return $att;
                      }


if ($value eq 'IPO'){
        my $offset=0x02;
        my $address = $self->hexAdder("$offset","$base");
        my $ipo;
        $output = $self->eepromDecode("$address");
        $output = substr($output,2,1);
        if ($output == '0') {$ipo = "OFF";}
        if ($output == '1') {$ipo = "ON";}
        if($verbose){print "VFO $vfo\[$band\] - IPO is $ipo\n"};
return $ipo;
                      }


if ($value eq 'FMSTEP'){
        my $offset=0x03;
        my $address = $self->hexAdder("$offset","$base");
        $output = $self->eepromDecode("$address");
        $output = substr($output,5,3);
        ($fmstep) = grep { $FMSTEP{$_} eq $output } keys %FMSTEP;
        if($verbose){print "VFO $vfo\[$band\] - FM STEP is $fmstep\n"};
return $fmstep;
                      }



if ($value eq 'AMSTEP'){
        my $offset=0x03;
        my $address = $self->hexAdder("$offset","$base");
        $output = $self->eepromDecode("$address");
        $output = substr($output,2,3);
        ($amstep) = grep { $AMSTEP{$_} eq $output } keys %AMSTEP;
        if($verbose){print "VFO $vfo\[$band\] - AM STEP is $amstep\n"};
return $amstep;
                      }



if ($value eq 'SSBSTEP'){
        my $offset=0x03;
        my $address = $self->hexAdder("$offset","$base");
        my $ssbstep;
        $output = $self->eepromDecode("$address");
        $output = substr($output,0,2);
        if ($output == '00') {$ssbstep = '1.0';}
        if ($output == '01') {$ssbstep = '2.5';}
	if ($output == '10') {$ssbstep = '5.0';}
        if($verbose){print "VFO $vfo\[$band\] - SSB STEP is $ssbstep\n"};
return $ssbstep;
                      }


if ($value eq 'CTCSSTONE'){
        my $offset=0x06;
        my ($MSB, $LSB) = $self->hexAdder("$offset","$base");
        $output = $self->eepromDecode("$MSB","$LSB");
        $output = substr($output,2,6);
        my %newhash = reverse %CTCSSTONES;
        ($ctcsstone) = grep { $newhash{$_} eq $output } keys %newhash;
        if($verbose){print "VFO $vfo\[$band\] - CTCSS TONE is $ctcsstone\n"};
return $ctcsstone;
                           }



if ($value eq 'DCSCODE'){
        my $offset=0x07;
        my $address = $self->hexAdder("$offset","$base");
        $output = $self->eepromDecode("$address");
        $output = substr($output,1,7);
        my %newhash = reverse %DCSCODES;
        ($dcscode) = grep { $newhash{$_} eq $output } keys %newhash;
        if($verbose){print "VFO $vfo\[$band\] - DCSCODE is $dcscode\n"};
return $dcscode;
                           }


               }


#################################
# WRITE VALUES FROM EEPROM ADDR #
#################################


# 55 ################################# SET VFO A/B , MEM OR VFO, MTQMB, QMB, HOME ######
###################################### SET BITS 0,1,2,4,5 AND 7 FROM 0X55

#55	0	VFO A/B	0 = VFO-A, 1 = VFO-B
#55	1	MTQMB Select	0 = (Not MTQMB), 1 = MTQMB
#55	2	QMB Select	0 = (Not QMB), 1 = QMB
#55	3	?	?
#55	4	Home Select	0 = (Not HOME), 1 = HOME memory
#55	5	Memory/MTUNE select	0 = Memory, 1 = MTUNE
#55	6	?	?
#55	7	MEM/VFO Select	0 = Memory, 1 = VFO (A or B - see bit 0)






# 57 ################################# SET AGC MODE, NOISE BLOCK, FASTTUNE , DSP AND LOCK ######
###################################### READ BITS 0-1 , 2, 5 AND 6 FROM 0X57

sub setAgc {
        my $self=shift;
	my $value=shift;
        if ($value ne 'AUTO' && $value ne 'SLOW' && $value ne 'FAST' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose AUTO/SLOW/FAST/OFF\n\n"; }
return 1;
                                                                                        }
        $self->setVerbose(0);
        my $currentagc = $self->getAgc();
        $self->setVerbose(1);
        if ($value eq $currentagc){
                if($verbose){print "Value $currentagc already selected.\n\n"; }
return 1;
                                  }

        my $BYTE1 = $self->eepromDecode('0057');
        if ($value eq 'OFF'){substr ($BYTE1, 6, 2, '11');}
        if ($value eq 'SLOW'){substr ($BYTE1, 6, 2, '10');}
        if ($value eq 'FAST'){substr ($BYTE1, 6, 2, '01');}
        if ($value eq 'AUTO'){substr ($BYTE1, 6, 2, '00');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0057',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"AGC Set to $value sucessfull!\n";}
                else {print"AGC set failed: $writestatus\n";}
                $writestatus = 'ERROR';
                    }
return $writestatus;
           }

####################

sub setNb {
        my ($currentnb) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n"; }
return 1;
                                              }
        $self->setVerbose(0);
        $currentnb = $self->getNb();
        $self->setVerbose(1);

        if ($value eq $currentnb){
                if($verbose){print "Value $currentnb already selected.\n\n"; }
return 1;
                                   }

        if($value eq 'ON'){$writestatus = $self->writeEeprom('0057','2','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0057','2','0');}

        if ($verbose){
                if ($writestatus eq 'OK') {print"Noise Block set to $value sucessfull!\n";}
                else {print"Noise Block set to $value failed!!!\n";}
                     }

return $writestatus;

           }

####################


sub setDsp {
        my ($currentdsp) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n"; }
return 1;
                                              }
        $self->setVerbose(0);
        $currentdsp = $self->getDsp();
        $self->setVerbose(1);

        if ($value eq $currentdsp){
                if($verbose){print "Value $currentdsp already selected.\n\n"; }
return 1;
                                   }

        if($value eq 'ON'){$writestatus = $self->writeEeprom('0057','5','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0057','5','0');}

        if ($verbose){
                if ($writestatus eq 'OK') {print"DSP set to $value sucessfull!\n";}
                else {print"DSP set to $value failed!!!\n";}
                     }

return $writestatus;

           }

####################


sub setPbt {
        my ($currentpbt) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n"; }
return 1;
                                              }
        $self->setVerbose(0);
        $currentpbt = $self->getPbt();
        $self->setVerbose(1);

        if ($value eq $currentpbt){
                if($verbose){print "Value $currentpbt already selected.\n\n"; }
return 1;
                                   }

        if($value eq 'ON'){$writestatus = $self->writeEeprom('0057','3','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0057','3','0');}

        if ($verbose){
                if ($writestatus eq 'OK') {print"Pass Band Tuning set to $value sucessfull!\n";}
                else {print"Pass Band Tuning set to $value failed!!!\n";}
                     }

return $writestatus;

           }


####################


sub setFasttuning {
        my ($currenttuning) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n"; }
return 1;
                                              }
        $self->setVerbose(0);
        $currenttuning = $self->getFasttuning();
        $self->setVerbose(1);

        if ($value eq $currenttuning){
                if($verbose){print "Value $currenttuning already selected.\n\n"; }
return 1;
                                     }

        if($value eq 'ON'){$writestatus = $self->writeEeprom('0057','0','0');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0057','0','1');}

        if ($verbose){
                if ($writestatus eq 'OK') {print"Fast Tuning set to $value sucessfull!\n";}
                else {print"Fast Tuning set to $value failed!!!\n";}
                     }

return $writestatus;

           }


# 58 ################################# SET VOX ######
###################################### CHANGE BIT 7 FROM 0X58

sub setVox {
        my ($currentvox) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n"; }
return 1;
                                              }

        $self->setVerbose(0);
        $currentvox = $self->getVox();
        $self->setVerbose(1);

        if ($value eq $currentvox){
                if($verbose){print "Value $currentvox already selected.\n\n"; }
return 1;
                                   }


        if($value eq 'ON'){$writestatus = $self->writeEeprom('0058','0','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0058','0','0');}


        if ($verbose){
                if ($writestatus eq 'OK') {print"VOX set to $value sucessfull!\n";}
                else {print"VOX set to $value failed!!!\n";}
                     }

return $writestatus;

           }


# 59 ################################# SET VFOBAND ######
###################################### CHANGE ALL BITS FROM 0X59

sub setVfoband {

       my ($currentband, $writestatus, $vfoband, $testvfoband) = @_;
        my $self=shift;
        my $vfo=shift;
        my $value=shift;

        if ($vfo ne 'A' && $vfo ne 'B'){
                if($verbose){print "Value invalid: Choose VFO A/B\n\n"; }
return 1;
                                      }

        my %newhash = reverse %VFOBANDS;
        ($testvfoband) = grep { $newhash{$_} eq $value } keys %newhash;


        if ($testvfoband eq'') {
                if($verbose){print "\nChoose valid Band : [160M/75M/40M/30M/20M/17M/15M/12M/10M/6M/2M/70CM/FMBC/AIR/PHAN]\n\n";}
return 1;
                               }
        $self->setVerbose(0);
        $currentband = $self->getVfoband("$vfo");
        $self->setVerbose(1);
        if ($currentband eq $value) {
                if($verbose){print "\nBand $currentband already selected for VFO $vfo\n\n"; }
return 1;
                                    }
        my $BYTE1 = $self->eepromDecode('0059');
        if ($vfo eq 'A'){substr ($BYTE1, 4, 4, "$testvfoband");}
        if ($vfo eq 'B'){substr ($BYTE1, 0, 4, "$testvfoband");}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
         $writestatus = $self->writeBlock('0059',"$NEWHEX");
        if ($verbose){
                if ($writestatus eq 'OK') {print"BAND $currentband on VFO $vfo set sucessfull!\n";}
                else {print"BAND $currentband on VFO $vfo set failed!!!\n";}
                     }

return $writestatus;
               }


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

        my $BYTE1 = $self->eepromDecode('005D');
        if ($value eq 'OFF'){substr ($BYTE1, 0, 2, '00');}
        if ($value eq 'RANGE'){substr ($BYTE1, 0, 2, '01');}
        if ($value eq 'ALL'){substr ($BYTE1, 0, 2, '10');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );

        $writestatus = $self->writeBlock('005D',"$NEWHEX");

        if($verbose){
                if ($writestatus eq 'OK') {print"ARTS Mode Set to $value sucessfull!\n";}
                else {print"ARTS Mode set failed: $writestatus\n";}
                $writestatus = 'ERROR';
                    }
return $writestatus;
		 }


# 5F ################################# SETS RFKNOB FUNCTION
###################################### SETS BIT 7 FROM ADDRESS 0X5F

sub setRfknob {
        my ($sqlbit, $writestatus,$currentknob) = @_;
        my $self=shift;
	my $value=shift;
        if ($value ne 'RFGAIN' && $value ne 'SQUELCH'){
                if($verbose){print "Value invalid: Choose RFGAIN/SQUELCH\n\n"; }
return 1;
	                                              }

        $self->setVerbose(0);
        $currentknob = $self->getRfknob();
        $self->setVerbose(1);
        if ($currentknob eq $value) {
                if($verbose){print "\nSetting $currentknob already selected for RFGAIN Knob\n\n"; }
return 1;
                                    }

        if($value eq 'RFGAIN'){$writestatus = $self->writeEeprom('005F','0','0');}
        if($value eq 'SQUELCH'){$writestatus = $self->writeEeprom('005F','0','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"RFGAIN Knob set to $value sucessfull!\n";}
                else {print"RFGAIN Knob set to $value failed!!!\n";}
                     }

return $writestatus;
                  }


# 62 ################################# SET CHARGETIME
###################################### CHANGE BITS 6-7 FROM ADDRESS 0X62

sub setChargetime {
        my ($chargebits, $writestatus1, $writestatus2, $writestatus3, $writestatus4, $writestatus5, $writestatus6, $changebits, $change7bbit) = @_;
        my $self=shift;
	my $value=shift;
        $output = $self->eepromDecode('0062');
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

	my $BYTE1 = $self->eepromDecode('0062');
	if ($value == '6'){substr ($BYTE1, 0, 2, '00');}
        if ($value == '8'){substr ($BYTE1, 0, 2, '01');}
        if ($value == '10'){substr ($BYTE1, 0, 2, '10');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
	$writestatus = $self->writeBlock('0062',"$NEWHEX");

        if($debug){print "Writing New BYTES to 0x62\n";}
        if($debug){print "Writing New BYTES to 0x7b\n";}

        $BYTE1 = $self->eepromDecode('007B');
        if ($value == '6'){substr ($BYTE1, 4, 4, '0110');}
        if ($value == '8'){substr ($BYTE1, 4, 4, '1000');}
        if ($value == '10'){substr ($BYTE1, 4, 4, '1010');}
        $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );	
         $writestatus2 = $self->writeBlock('007B',"$NEWHEX");


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

        if($value eq 'ON'){$writestatus = $self->writeEeprom('0079','0','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0079','0','0');}

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

        $writestatus = $self->writeEeprom('007A',"$antennabit","$value2");

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
        if ($value eq 'OFF'){$writestatus = $self->writeEeprom('007B','3','0');}
	if ($value eq 'ON'){$writestatus = $self->writeEeprom('007B','3','1');}
return 0;
	     }




return 1;

               }






=head1 NAME

Ham::Device::FT817COMM - Library to control the Yaesu FT817 Ham Radio

=head1 VERSION

Version 0.9.0_10

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

	$output = $FT817->setLock('ON');

Using this method, the output which is collected in the varible B<$output> is designed to be minimal for
use in applications that provide an already formatted output.

For example:
	
	$output = $FT817->setLock('ON');
	print "$output";

Would simply return B<F0> if the command failed and B<00> if the command was sucessfull. The outputs vary
from module to module, depending on the function

=head2 2. Using setVerbose()

The module already has pre-formatted outputs for each subroutine.  Using the same example in a different form
and setting B<setVerbose(1)> we have the following

	setVerbose(1);
	$FT817->setLock('ON');

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

	if (($FT817->gethome()) eq 'Y') {
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

	$FT817->setDebug(1); # Turns on the debugger

The first output of which is:

	DEBUGGER IS ON

Two distinct type of transactions happen with the debugger, they are:

	CAT commands   :	Commands which use the Yaesu CAT protocol
	EPROMM commands:	Commands which read and write to the EEPROM

With the command: B<getMode()> we get the regular output expected, with B<verbose(1)>

	Mode is FM

However with the B<setDebug(1)> we will see the following output to the same command:

	[FT817]@/dev/ttyUSB0$ get mode

	(sendCat:DEBUG) - DATA OUT ------> 00 00 00 00 03

	(sendCat:DEBUG) - BUILT PACKET --> 0000000003

	(sendCat:DEBUG) - DATA IN <------- 1471200008

	Mode is FM
	[FT817]@/dev/ttyUSB0$ 

The sendcat:debug shows the request of B<00 00 00 00 0x03> sent to the rig, and the rig
returning B<1471200008>. What were looking at is the last two digits 08 which is parsed from
the block of data.  08 is mode FM.  FT817COMM does all of the parsing and conversion for you.

As you might have guessed, the first 8 digits are the current frequency, which in this case
is 147.120 MHZ.  The getFrequency() module would pull the exact same data, but parse it differently

The debugger works differently on read/write to the eeprom. The next example shown below used the function
B<setArts('OFF')>, the function which tunrs arts off.


	[FT817]@/dev/ttyUSB0$ set arts off

	(eepromDecode:DEBUG) - READING FROM ------> [00x79]

	(eepromDecode:DEBUG) - PACKET BUILT ------> [00790000BB]

	(eepromDecode:DEBUG) - OUTPUT HEX  -------> [81]

	(eepromDecode:DEBUG) - OUTPUT BIN  -------> [10000001]


	(writeEeprom:DEBUG) - OUTPUT FROM [00x79]

	(writeEeprom:DEBUG) - PACKET BUILT ------> [00790000BB]

	(writeEeprom:DEBUG) - BYTE1 (81) BYTE2 (1F) from [00x79]

	(writeEeprom:DEBUG) - BYTE1 BINARY IS [10000001]

	(writeEeprom:DEBUG) - CHANGING BIT(0) to (0)

	(writeEeprom:DEBUG) - BYTE1: BINARY IS [00000001] AFTER CHANGE

	(writeEeprom:DEBUG) - CHECKING IF [1] needs padding

	(writeEeprom:DEBUG) - Padded to [01]

	(writeEeprom:DEBUG) - BYTE1 (01) BYTE2 (1F) to   [00x79]

	(writeEeprom:DEBUG) - WRITING  ----------> (01) (1F)

	(writeEeprom:DEBUG) - PACKET BUILT ------> [0079011fBC]

	(writeEeprom:DEBUG) - VALUES WRITTEN, CHECKING...

	(writeEeprom:DEBUG) - SHOULD BE: (01) (1F)

	(writeEeprom:DEBUG) - IS: -----> (01) (1F)

	(writeEeprom:DEBUG) - VALUES MATCH!!!

	ARTS set to OFF sucessfull!

The output shows all of the transactions and modifications conducted by the system functions


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


=item getChecksum()

                $checksum = $FT817->getChecksum();

	Returns the checksum bits in EEPROM areas 0x00 through 0x03


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
	output of the memory address specified.

With one argument it will display the information about a memory address 

	[FT817]@/dev/ttyUSB0$ get eeprom 005f

	ADDRESS     BINARY          DECIMAL     VALUE      
	___________________________________________________
	005F        11100101        229         E5    


With two arguments it will display information on a range of addresses

	[FT817]@/dev/ttyUSB0$ get eeprom 005f 0062

	ADDRESS     BINARY          DECIMAL     VALUE      
	___________________________________________________
	005F        11100101        229         E5         
	0060        00011001        25          19         
	0061        00110010        50          32         
	0062        10001000        136         88  


=item getFasttuning()

		$fasttune = $FT817->getFasttuning();

	Returns the current setting of the Fast Tuning mode : ON / OFF


=item getFlags()

		$flags = $FT817->getFlags();

	Returns the current status of the flags : DEBUG / VERBOSE / WRITE ALLOW / WARNED


=item getFrequency()

		$frequency = $FT817->getFrequency([#]);

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


=item getPbt ()

                $pbt = $FT817->getPbt();

        Returns the status of Pass Band Tuning: ON /OFF


=item getRfknob()

		$rfknob = $FT817->getRfknob();

	Returns the current Functionality of the RF-GAIN Knob : RFGAIN / SQUELCH


=item getRxstatus()

		$rxstatus = $FT817->getRxstatus([VARIABLES/HASH]);

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

		$txstatus = $FT817->getTxstatus([VARIABLES/HASH]);

	Retrieves the status of POWERMETER / PTT / HIGHSWR / SPLIT in one
	command and posts the information when verbose(1).  

	Returns with variables as argument $pometer $ptt $highswr $split
	Returns with hash as argument %txstatus


=item getVfo()

		$vfo = $FT817->getVfo();

	Returns the current VFO : A / B


=item getVfoband()

                $vfoband = $FT817->getVfoband([A/B]);

        Returns the current band of a given VFO 


=item getVox()

                $vox = $FT817->getVox();

        Returns the status of VOX : ON / OFF


=item hex2bin()

	Simple internal function for convrting hex to binary. Has no use to the end user.


=item hexDiff()

        Internal function to return decimal value as the difference between two hex numbers


=item hexAdder()

	Internal function to incriment a given hex value off a base address


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


=item readMemvfo ()

		my $option = $FT817->readMemvfo('[A/B]', '[BAND]', '[OPTION]');

	Reads and returns information from the VFO memory given a VFO [A/B] and a BAND [20M/40M/70CM] etc..
	This is only for VFO memory's and not the Stored Memories nor Home Memories

	Returns information based on one of the valid options:

	MODE      - Returns the mode in memory - update only appears after toggling the VFO
	NARFM     - Returns if Narrow FM os ON or OFF
	NARCWDIG  - Returns if the CW or Digital Mode is on Narrow
	RPTOFFSET - Returns the Repeater offset
	TONEDCS   - Returns type type of tone being used
	ATT       - Returns if ATT is on if applicable, if not shows OFF
	IPO       - Returns if IPO is on if applicable, if not shows OFF
	FMSTEP    - Returns the setting for FM STEP in KHZ
	AMSTEP    - Returns the setting for AM STEP in KHZ
        SSBSTEP   - Returns the setting for SSB STEP in KHZ
	CTCSSTONE - Returns the currently set CTCSS Tone
	DCSCODE   - Returns the currently set DCS Code


=item restoreEeprom()

		$restorearea = $FT817->restoreEeprom();

	This restores a specific memory area of the EEPROM back to a known good default value.
	This is a WRITEEEPROM based function and requires both setWriteallow() and agreeWithwarning()
	to be set to 1.
	This command does not allow for an arbitrary address to be written. 
	Currently [0057] [0058] [0059] [005D] [005F] [0062] [0079] [007A] and [007B] are allowed

	restoreEeprom('005F'); 

	Returns 'OK' on success. Any other output an error.


=item sendCat()

	Internal function, if you try to call it, you may very well end up with a broken radio.
	You have been warned.


=item setAntenna()

                $status = $FT817->setAntenna([HF/6M/FMBCB/AIR/VHF/UHF] [FRONT/BACK]);

	Sets the antenna for the given band as connected on the FRONT or REAR of the radio

	This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('007A');


=item setAgc()

                $status = $FT817->setAgc([AUTO/FAST/SLOW/OFF];

        Sets the agc

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0057');


=item setArts()

                $arts = $FT817->setArts([ON/OFF]);

	Sets the ARTS function of the radio to ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0079');


=item setArtsmode()

                $artsmode = $FT817->setArts([OFF/RANGE/BEEP]);

        Sets the ARTS function of the radio when ARTS is enables

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005D');


=item setCharger()

                $charger = $FT817->setCharger([ON/OFF]);

        Turns the battery Charger on or off
	This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('007B');


=item setChargetime()

                $chargetime = $FT817->setChargetime([6/8/10]);

        Sets the Battery charge time to 6, 8 or 10 hours.  If the charger is currently
	on, it will return an error and not allow the change. Charger must be off.
	This is a WRITEEEPROM based function and requires both setWriteallow() and
	agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        commands that also requires both flags previously mentioned set to 1.

        restoreEeprom('0062');
	restoreEeprom('007B');

        Returns 'OK' on success. Any other optput an error.


=item setClarifier()

		$setclar = $FT817->setClarifier([ON/OFF]);

	Enables or disables the clarifier

	Returns '00' on success or 'f0' on failure


=item setClarifierfreq()

		$setclarfreq = $FT817->setClarifierfreq([####]);

	Uses 4 digits as an argument to set the Clarifier frequency.  Leading and trailing zeros required where applicable
	 1.234 KHZ would be 1234

	Returns '00' on success or 'f0' on failure


=item setCtcssdcs()

		$ctcssdcs = $FT817->setCtcssdcs({DCS/CTCSS/ENCODER/OFF});

	Sets the CTCSS DCS mode of the radio

	Returns 'OK' on success or something else on failure


=item setCtcsstone()

		$ctcsstone = $FT817->setCtcsstone([####]);

	Uses 4 digits as an argument to set the CTCSS tone.  Leading and trailing zeros required where applicable
	 192.8 would be 1928 as an argument

	Returns '00' on success or 'f0' on failure
	On 'f0' verbose(1) displays all valid tones


=item setDcscode()

		$dcscode = $FT817->setDcscode([####]);

	Uses 4 digits as an argument to set the DCS code.  Leading and trailing zeros required where applicable
	 0546 would be 546 as an argument

	Returns '00' on success or 'f0' on failure
	On 'f0' verbose(1) displays all valid tones


=item setDebug()

		$debug = $FT817->setDebug([#]);

	Turns on and off the internal debugger. Provides information on all serial transactions when on.
	Activated when any value is in the (). Good practive says () or (1) for OFF and ON.

	Returns the argument sent to it on success.


=item setDsp()

                $output = $FT817->setDsp([ON/OFF]);

        Turns the DSP on or off if available

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0057');


=item setFasttuning()

                $output = $FT817->setFasttuning([ON/OFF]);

        Sets the Fast Tuning of the radio to ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0057');


=item setFrequency()

		$setfreq = $FT817->setFrequency([########]);

	Uses 8 digits as an argument to set the frequency.  Leading and trailing zeros required where applicable
	147.120 MHZ would be 14712000
	 14.070 MHZ would be 01407000

	Returns '00' on success or 'f0' on failure


=item setLock()

		$setlock = $FT817->setLock([ON/OFF]);

	Enables or disables the radio lock.

	Returns '00' on success or 'f0' on failure


=item setMode()

		$setmode = $FT817->setMode([LSB/USB/CW/CWR/AM/FM/DIG/PKT/FMN/WFM]);

	Sets the mode of the radio with one of the valid modes.

	Returns '00' on success or 'f0' on failure


=item setNb()

                $output = $FT817->setNb([ON/OFF]);

	Turns the Noise Blocker on or off

	This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0057');

        Returns 'OK' on success. Any other optput an error.


=item setOffsetfreq()

		$offsetfreq = $FT817->setOffsetfreq([########]);

	Uses 8 digits as an argument to set the offset frequency.  Leading and trailing zeros required where applicable
	1.230 MHZ would be 00123000

	Returns '00' on success or 'f0' on failure


=item setOffsetmode()

		$setoffsetmode = $FT817->setOffsetmode([POS/NEG/SIMPLEX]);

	Sets the mode of the radio with one of the valid modes.

	Returns '00' on success or 'f0' on failure


=item setPbt()

                $status = $FT817->setPbt([OFF/ON];

        Enables or disables the Pass Band Tuning

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0057');


=item setPower()

		$setPower = $FT817->setPower([ON/OFF]);

	Sets the power of the radio on or off. Note that this function, as stated in the manual only works
	Correctly when connected to DC power and NO Battery installed 

	Returns '00' on success or 'null' on failure


=item setPtt()

		$setptt = $FT817->setPtt([ON/OFF]);

	Sets the Push to talk of the radio on or off.  

	Returns '00' on success or 'f0' on failure


=item setRfknob()

                $rfknob = $FT817->setRfknob([RFGAIN/SQUELCH]);

        SETS THE RF-GAIN knob functionality.  

	This is a WRITEEEPROM based function and requires both setWriteallow() and 
	agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005F');

        Returns 'OK' on success. Any other optput an error.


=item setSplitfreq()

		$setsplit = $FT817->setSplitfreq([ON/OFF]);

	Sets the radio to split the transmit and receive frequencies

	Returns '00' on success or 'f0' on failure


=item setVfoband()

                $setvfoband = $FT817->setVfoband([A/B] [160M/75M/40M/30M/20M/17M/15M/12M/10M/6M/2M/70CM/FMBC/AIR/PHAN]);

        Sets the band of the selected VFO

        Returns 'OK' on success or '1' on failure


=item setVox()

                $setvox = $FT817->setVox([ON/OFF]);

        Sets the VOX feature of the radio on or off.

        Returns 'OK' on success or '1' on failure


=item setWriteallow()

		$writeallow = $FT817->setWriteallow([#]);

	Turns on and off the write Flag. Provides a warning about writing to the EEPROM and
	requires the agreeWithwarning()  to also be set to 1 after reading the warning
	Activated when any value is in the (). Good practive says () or (1) for OFF and ON.

	Returns the argument sent to it on success.


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
