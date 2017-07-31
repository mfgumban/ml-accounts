xquery version "1.0-ml";
import module namespace rest = "http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace acc = "http://marklogic.com/ml-common-services/accounts" at "/api/accounts.xqy";


let $request := $requests:options/rest:request[@endpoint = "/rest/accounts-deactivate.xqy"][1]
let $params := rest:process-request($request)
let $account-name := map:get($params, "account-name")

return (
  xdmp:set-response-code(200, "OK"),
  acc:deactivate($account-name)
)
