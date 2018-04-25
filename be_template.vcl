
backend %BE_NAME% {
    .host = "%BE_IP%";
    .port = "%BE_PORT%";
    .probe = {
        .url = "%BE_PATH%";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}
