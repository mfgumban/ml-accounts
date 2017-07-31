xquery version "1.0-ml";
module namespace requests = "http://marklogic.com/appservices/requests";
import module namespace rest = "http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";


declare variable $requests:options as element(rest:options) :=
<options xmlns="http://marklogic.com/appservices/rest" >
  <request uri="^/accounts/([^/]+)$" endpoint="/rest/accounts-get.xqy">
    <uri-param name="account-name">$1</uri-param>
    <http method="GET">
    </http>
  </request>
  <request uri="^/accounts/([^/]+)/activate$" endpoint="/rest/accounts-activate.xqy">
    <uri-param name="account-name">$1</uri-param>
    <http method="POST">
    </http>
  </request>
  <request uri="^/accounts/([^/]+)/deactivate$" endpoint="/rest/accounts-deactivate.xqy">
    <uri-param name="account-name">$1</uri-param>
    <http method="POST">
    </http>
  </request>
</options>;
