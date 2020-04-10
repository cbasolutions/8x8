#!/usr/bin/env bash

customerID=""
accessToken=""

headers="-H \"Accept: application/json\" -H \"Content-type: application/json\" -H \"Authorization: Bearer ${accessToken}\""
url="https://platform.8x8.com/udi/customers/${customerID}/scim/v2/Users"
{
read
while IFS=, read -r FN LN EM UN EID
do
  echo ${FN} ${LN} ${EM} ${UN} ${EID}
  data='{"userName":"'${UN}'","name": {"familyName":"'${LN}'","givenName":"'${FN}'"},"active": true,"locale": "en-US","emails": [{"value": "'${EM}'","type": "work","primary": true}],"externalId":"'${EID}'"}'
  curl ${url} -H ${headers} -X POST -d "${data}" 
done
} < 8x8_import_template.csv
