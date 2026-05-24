---------------------------------------------------------------------------
-- Snort 3 Configuration File
-- Container 2: IDS/IPS Hybrid Mode
-- Project 3 - Keamanan Sistem
---------------------------------------------------------------------------

-- ========================================
-- 1. NETWORK VARIABLES
-- ========================================
HOME_NET = '10.10.10.10/32'    -- Web Server (Container 1)
EXTERNAL_NET = '!$HOME_NET'

-- Network lists
DNS_SERVERS = '$HOME_NET'
SMTP_SERVERS = '$HOME_NET'
HTTP_SERVERS = '$HOME_NET'
SQL_SERVERS = '$HOME_NET'
TELNET_SERVERS = '$HOME_NET'
SSH_SERVERS = '$HOME_NET'

-- Port lists
HTTP_PORTS = '80 443 8080'
SSH_PORTS = '22'

-- Load default variables (must be AFTER variable definitions above)
include '/etc/snort/config/snort_defaults.lua'

-- ========================================
-- 2. PATH VARIABLES
-- ========================================
RULE_PATH = '/etc/snort/rules'
BUILTIN_RULE_PATH = '/usr/local/etc/rules'
PLUGIN_RULE_PATH = '/usr/local/etc/so_rules'

-- ========================================
-- 3. DAQ (Data Acquisition) CONFIGURATION
-- Inline IPS mode using NFQUEUE
-- ========================================
daq = {
    modules = {
        {
            name = 'nfq',
            mode = 'inline',
            variables = {
                'queue=1',
                'queue_maxlen=4096'
            }
        }
    }
}

-- ========================================
-- 4. DETECTION ENGINE
-- ========================================
detection = {
    pcre_match_limit = 3500,
    pcre_match_limit_recursion = 1500,
}

-- ========================================
-- 5. IPS POLICY (Inline Mode)
-- ========================================
ips = {
    mode = 'inline',
    enable_builtin_rules = true,
    variables = default_variables,
    rules = [[
        include /etc/snort/rules/local.rules
    ]]
}

-- ========================================
-- 6. STREAM / NETWORK
-- ========================================

-- Stream reassembly
stream = { }
stream_tcp = {
    policy = 'linux',
    session_timeout = 180,
}
stream_udp = {
    session_timeout = 180
}
stream_icmp = { }

-- ========================================
-- 7. OUTPUT / ALERTS
-- ========================================

-- Fast alert output to file
alert_fast = {
    file = false,
    packet = false,
}

-- Full alert with packet data
alert_full = {
    file = true,
}

-- ========================================
-- 8. LOGGING
-- ========================================

-- Log packets
log_codecs = { }
