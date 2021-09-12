#!/bin/bash

HEADER_FROM=`echo $1 | sed 's/</ - /g' | sed 's/>//g'`
HEADER_SUBJECT=`echo $2 | sed 's/"//g'`
HEADER_TO=`echo $3 | sed 's/</ - /g' | sed 's/>//g'`
HEADER_TO_MAIL=`echo $3 | grep -i -o '[A-Z0-9._%+-]\+@[A-Z0-9.-]\+\.[A-Z]\{2,6\}'`

CURR_DATE=`/bin/date +%Y.%m.%d_%H.%M.%S`
DEBUG_LOG=/var/log/mail.debug

echo "----------" >> $DEBUG_LOG
echo $CURR_DATE >> $DEBUG_LOG
echo HEADER_TO: $HEADER_TO >> $DEBUG_LOG
echo HEADER_TO_MAIL: $HEADER_TO_MAIL >> $DEBUG_LOG
echo HEADER_FROM: $HEADER_FROM >> $DEBUG_LOG
echo HEADER_SUBJECT: $HEADER_SUBJECT >> $DEBUG_LOG

generate_post_data()
{
cat << EOF
{
    "msgtype":"m.text",
    "body":"От: $HEADER_FROM\\nКому: $HEADER_TO\\nТема: $HEADER_SUBJECT",
    "formatted_body":"<b>От кого</b>: $HEADER_FROM<br><b>Кому</b>: $HEADER_TO<br><b>Тема</b>: $HEADER_SUBJECT",
    "format":"org.matrix.custom.html"
}
EOF
}

# exmaple of MATRIX_SERVER: "https://matrix.myexample.com"
# example of ROOM_ID: !NN3esaYJO33kovdcBt:matrix.myexample.com (in room Settings -> Advanced)
# example of ACCESS_TOKEN: MDaxkfioj9eh983uO...mIyYm1haweqwe3esNA-ph4qe2_24wCg (in account Settings -> Help & About -> Access Token)

MATRIX_SERVER="https://matrix.myexample.com"
ACCESS_TOKEN="MDAxYmxvY2F0aW9uIHByb2ZhZG1pbi5jb20KMDAxM2lkZW5...0aWZpZXIga2V5CjAwMTBjaWQgZ2VuID0gZSAO-QCZvLk9NR49U-I_CxsCDW3KY40XBpvkOogjPJ_KNQo"

if [ $HEADER_TO_MAIL == "user@myexample.com" ];
then
    ROOM_ID="!ZveqosTf123456hPDV:myexample.com"
fi

curl -XPOST -d "$(generate_post_data)" "$MATRIX_SERVER/_matrix/client/r0/rooms/$ROOM_ID/send/m.room.message?access_token=$ACCESS_TOKEN"
