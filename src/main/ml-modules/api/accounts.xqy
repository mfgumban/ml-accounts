xquery version "1.0-ml";
module namespace acc = "http://marklogic.com/ml-common-services/accounts";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";


declare variable $accounts-user-role := "accounts-role";
declare variable $accounts-admin-role := "accounts-admin-role";


declare function acc:get($username as xs:string)
{
  fn:doc(acc:get-account-uri($username))
};

(:
  Creates a new account.
:)
declare function acc:create($username as xs:string, $email as xs:string, $data as node()*)
{
  let $_ := (
    if (acc:has-user($username)) then fn:error(xs:QName("ACC-USEREXISTS"), "A user with the same username exists.") else (),
    if (acc:has-account-doc($username)) then fn:error(xs:QName("ACC-ACCEXISTS"), "An account with the same username exists.") else ()
  )

  let $uri := acc:get-account-uri($username)
  let $account := acc:create-account-doc($username, $email, $data)

  return (
    xdmp:document-insert($uri, $account, acc:get-account-permissions(), acc:get-account-collections())
  )
};

declare function acc:activate($username as xs:string, $password as xs:string, $activation-code as xs:string)
{
  let $uri := acc:get-account-uri($username)
  let $account := fn:doc($uri)
  let $_ := (
    if (fn:empty($account)) then fn:error(xs:QName("ACC-DOESNOTEXIST"), "The specified username has no account.") else (),
    if ($account/acc:account/acc:activated/fn:string() eq "true") then fn:error(xs:QName("ACC-ACTIVATED"), "The specified account is already activated.") else (),
    if ($activation-code ne $account/acc:account/acc:activation-code/fn:string()) then fn:error(xs:QName("ACC-INVACTCODE"), "Invalid activation code.") else ()
  )

  let $now := fn:current-dateTime()
  let $account := 
  <acc:account>
    { $account/acc:account/*[fn:not(self::acc:activation)] }
    <acc:activation>
      <acc:activated>true</acc:activated>
      <acc:last-activated-on>{ $now }</acc:last-activated-on>
      <acc:last-activated-by>{ xdmp:get-current-user() }</acc:last-activated-by>
    </acc:activation>
  </acc:account>

  return (
    xdmp:invoke-function(
      function() { sec:create-user($username, "", $password, (), (), ()) },
      <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
        <database>{ xdmp:security-database() }</database>
      </options>
    ),
    xdmp:document-insert($uri, $account, acc:get-account-permissions(), acc:get-account-collections())
  )
};

declare function acc:deactivate($username as xs:string)
{
  let $uri := acc:get-account-uri($username)
  let $account := fn:doc($uri)
  let $_ := (
    if (fn:empty($account)) then fn:error(xs:QName("ACC-DOESNOTEXIST"), "The specified username has no account.") else (),
    if ($account/acc:account/acc:activated/fn:string() ne "true") then fn:error(xs:QName("ACC-NOTACTIVATED"), "The specified account is not activated.") else ()
  )

  let $now := fn:current-dateTime()
  let $account := 
  <acc:account>
    { $account/acc:account/*[fn:not(self::acc:activation)] }
    <acc:activation>
      <acc:activated>false</acc:activated>
      <acc:activation-code>{ acc:generate-activation-code() }</acc:activation-code>
      <acc:last-deactivated-on>{ $now }</acc:last-deactivated-on>
      <acc:last-deactivated-by>{ xdmp:get-current-user() }</acc:last-deactivated-by>
    </acc:activation>
  </acc:account>

  return (
    sec:remove-user($username),
    xdmp:document-insert($uri, $account, acc:get-account-permissions(), acc:get-account-collections())
  )
};

declare function acc:get-account-uri($username as xs:string)
as xs:string
{
  "/accounts/" || $username || ".xml"
};

declare function acc:create-account-doc($username as xs:string, $email as xs:string, $data as node()*)
as node()+
{
  let $now := fn:current-dateTime()

  return
  <acc:account>
    <acc:info>
      <acc:username>{ $username }</acc:username>
      <acc:email>{ $email }</acc:email>
      <acc:data>{ $data }</acc:data>
    </acc:info>
    <acc:activation>
      <acc:activation-code>{ acc:generate-activation-code() }</acc:activation-code>
      <acc:activated>false</acc:activated>
    </acc:activation>
    <acc:created-on>{ $now }</acc:created-on>
    <acc:created-by>{ xdmp:get-current-user() }</acc:created-by>
  </acc:account>
};

declare function acc:get-account-permissions()
as node()*
{
  (
    xdmp:permission($accounts-user-role, "read"),
    xdmp:permission($accounts-admin-role, "insert"),
    xdmp:permission($accounts-admin-role, "update")
  )
};

declare function acc:get-account-collections()
as xs:string*
{
  ("accounts")
};

declare function acc:has-user($username as xs:string)
{
  xdmp:invoke-function(
    function() { sec:user-exists($username) },
    <options xmlns="xdmp:eval">
      <transaction-mode>query</transaction-mode>
      <database>{ xdmp:security-database() }</database>
    </options>
  )
};

declare function acc:has-account-doc($username as xs:string)
{
  (: should be an index; still wondering how to decouple database bootstrap code :)
  fn:not(fn:empty(fn:doc(acc:get-account-uri($username))))
};

declare function acc:generate-activation-code()
as xs:string
{
  fn:replace(fn:concat(sem:uuid-string(), sem:uuid-string(), sem:uuid-string(), sem:uuid-string()), "-", "")
};
