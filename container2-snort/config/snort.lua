---------------------------------------------------------------------------
-- Snort 3 Configuration File
-- Container 2: IDS/IPS Hybrid Mode
-- Project 3 - Keamanan Sistem
---------------------------------------------------------------------------

include '/etc/snort/config/snort_defaults.lua'

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
-- search_engine = { search_method = 'hyperscan' }

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
        include /etc/snort/rules/community.rules
        include /etc/snort/rules/custom/web-attacks.rules
    ]]
}

-- ========================================
-- 6. PREPROCESSORS / INSPECTORS
-- ========================================

-- Normalize HTTP traffic
http_inspect = { }

-- Normalize HTTP2 traffic
http2_inspect = { }

-- SSL/TLS inspection
ssl = { }

-- DNS inspection
dns = { }

-- SSH inspection
ssh = { }

-- Stream reassembly
stream = { }

stream_tcp = {
    policy = 'linux',
    session_timeout = 180,
    max_window = 0,
    overlap_limit = 10,
    max_pdu = 16384,
    reassemble_async = true,
}

stream_udp = {
    session_timeout = 180
}

stream_icmp = { }

-- Port scan detection
port_scan = {
    protos = 'all',
    scan_types = 'all',
    watch_ip = [[
        10.10.10.30/32
    ]],
}

-- ========================================
-- 7. OUTPUT / ALERTS
-- ========================================

-- Fast alert output to file
alert_fast = {
    file = true,
    packet = false,
}

-- Full alert with packet data
alert_full = {
    file = true,
}

-- Unified2 output for analysis tools
-- unified2 = {
--     limit = 128,
-- }

-- Console output for real-time monitoring
--alert_fast = {
--    file = false,  -- stdout
--}

-- ========================================
-- 8. EVENT FILTERING
-- ========================================

-- Rate-based detection
rate_filter = {
    { gid = 1, sid = 1000031, track = 'by_src', count = 100, seconds = 10, 
      new_action = 'drop', timeout = 60 },
    { gid = 1, sid = 1000032, track = 'by_src', count = 50, seconds = 5,
      new_action = 'drop', timeout = 120 },
}

-- Suppress noisy rules if needed
-- suppress = {
--     { gid = 1, sid = 1000001 },
-- }

-- ========================================
-- 9. LOGGING
-- ========================================

-- Log packets
log_codecs = { }

-- Packet logger
-- log_pcap = { limit = 100 }
