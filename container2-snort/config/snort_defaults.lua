---------------------------------------------------------------------------
-- Snort 3 Default Variables
---------------------------------------------------------------------------

-- Default ftp command/response lengths
ftp_default_cmds = [[ ]]

-- Default variables (used by rules)
default_variables = {
    nets = {
        HOME_NET = HOME_NET,
        EXTERNAL_NET = EXTERNAL_NET,
        DNS_SERVERS = DNS_SERVERS,
        SMTP_SERVERS = SMTP_SERVERS,
        HTTP_SERVERS = HTTP_SERVERS,
        SQL_SERVERS = SQL_SERVERS,
        TELNET_SERVERS = TELNET_SERVERS,
        SSH_SERVERS = SSH_SERVERS,
    },
    ports = {
        HTTP_PORTS = HTTP_PORTS,
        SSH_PORTS = SSH_PORTS,
    },
}
