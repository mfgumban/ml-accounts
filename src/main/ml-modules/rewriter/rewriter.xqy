xquery version "1.0-ml";
import module namespace rest = "http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace req = "http://marklogic.com/appservices/requests" at "/rewriter/requests.xqy";


rest:rewrite($requests:options)
