vcl 4.0;

import std;

backend default {
    .host = "haproxy";
    .port = "80";
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;    
    }
}

sub vcl_recv {
    set req.http.host = "${REQ_HOST}";

    unset req.http.Cookie;
}

sub vcl_hit {
    if (!std.healthy(default) && (obj.ttl + obj.grace + obj.keep > 0s)) {
        return (deliver);
    }
}

sub vcl_backend_response {

    if (beresp.status == 503) {
        return (abandon);
    }

    ##unset beresp.http.Expires;  
    #unset beresp.http.Cache-Control;  
    #unset beresp.http.Pragma;  

    # Marker for vcl_deliver to reset Age: /  
    #set beresp.http.magicmarker = "1";  

    # Leveraging browser, cache set the clients TTL on this object /  
    set beresp.http.Cache-Control = "public, max-age=60";  

    # cache set the clients TTL on this object /  
    set beresp.ttl = 1m;  

    # Allow stale content, in case the backend goes down.  
    # make Varnish keep all objects for 6 hours beyond their TTL  
    ##set beresp.grace = 6h;    
    set beresp.grace = 10s;
    set beresp.keep = 24h;

    unset beresp.http.Cookie;

}
