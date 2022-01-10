package OPENC3::MYDan::UDPFileServer;

use strict;
use warnings;
$|++;

our %RUN = ( 
    MTU => 1400, 
    HEAD => 11,  #4T 
    WriteFileWidth => 100, 
    ACKInterval => 0.001, 
    WriteFileInterval => 0.001,
    RTT => 0.003, 
    MaxRTO => 0.2,
    SendSec => 2000, 
    ReadFileCache => 400000,
    TransmitRatio => 1.5,
    Buffers => 1000,
    SendTimeoutAddTime => 0.003,
    SendOne => 1000,
    ReadFileOneTime => 800,
);

1;
