vcl 4.0;

backend default {
    .host = "haproxy";
    .port = "80";
}

sub vcl_recv {
    set req.http.host = "portal.convenios.gov.br";

    unset req.http.Cookie;    

}

sub vcl_backend_response {

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

}
