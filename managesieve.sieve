require ["fileinto", "mime", "variables", "extracttext", "copy", "envelope", "vnd.dovecot.execute", "foreverypart"];
# rule:[mail_notifications_to_matrix]
if header :matches "from" "*"
{
        set "from" "${1}";
}

if header :matches "subject" "*"
{
        set "subject" "${1}";
}

if header :matches "to" "*"
{
        set "to" "${1}";
}

execute :output "notify_matrix" "send_msg_to_matrix.sh" ["${from}", "${subject}", "${to}"];
