Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

# PXML Todo

(See also functional-perl [[TODO]].)

* Handle tag and attribute names safely? For example:

        PXML::Element->new("<>", {"/" => 1}, [])

  will currently serialize to something like <<> /="1"></<>>

* use `HTML::Element`, as base class? Of course that won't work for
  general XML. `XML::LibXML` for the latter? Well.. Perhaps
  parametrizable?

* how are the rules with regards to URL escaping? No escaping, right?
  So should actually be fine? Check in detail, tests.

* tests are scattered to functional_XML/{test,testlazy},
  functional_XML/t/*, and lib/PXML/Preserialize/t.pm and
  lib/PXML/Serialize/t.pm, which is probably too much of a mess.

* clean up `PXML::Serialize`, it's an awful mess now (undo all those
  useless constant optimizations)

* make a proper hierarchy (`PXML::Element` and PXML::Body (in `PXML`)
  should probably have a common base class), move code to proper
  locations.

* optimization: examine whether it would be worthwhile to use mapping
  functions that reuse inputs if unchanged

