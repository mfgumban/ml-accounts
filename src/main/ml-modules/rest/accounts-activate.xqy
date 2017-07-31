xquery version "1.0-ml";
import module namespace rest = "http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace acc = "http://marklogic.com/ml-common-services/accounts" at "/api/accounts.xqy";


let $request := $requests:options/rest:request[@endpoint = "/rest/accounts-activate.xqy"][1]
let $params := rest:process-request($request)
let $account-name := map:get($params, "account-name")
let $request-body := xdmp:get-request-body()

return (
  xdmp:set-response-code(200, "OK"),
  acc:activate($account-name, $request-body/password, $request-body/activation-code)
)
