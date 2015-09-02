print ip2long("21.35.97.33")."\n";
print long2ip("354640161")."\n";
sub ip2long {
    my $long = unpack('N',(pack('C4',(split( /\./,$_[0])))));
    return $long;
}
sub long2ip {
    my @a = unpack('C4',(pack('N',$_[0]))); 
    my $ip = (join "\.",@a);
    return $ip;
}
