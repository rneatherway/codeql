/**
 * Provides a class for detecting string concatenations involving
 * the characters `?` and `#`, which are considered sanitizers for
 * the URL redirection queries.
 */

import javascript

/**
 * Holds if the string value of `nd` prevents anything appended after it
 * from affecting the hostname or path of a URL.
 *
 * Specifically, this holds if the string contains `?` or `#`.
 */
private predicate hasSanitizingSubstring(DataFlow::Node nd) {
  nd.asExpr().getStringValue().regexpMatch(".*[?#].*")
  or
  hasSanitizingSubstring(StringConcatenation::getAnOperand(nd))
  or
  hasSanitizingSubstring(nd.getAPredecessor())
  or
  nd.isIncomplete(_)
}

/**
 * Holds if data that flows from `source` to `sink` cannot affect the
 * path or earlier part of the resulting string when interpreted as a URL.
 *
 * This is considered as a sanitizing edge for the URL redirection queries.
 */
predicate sanitizingPrefixEdge(DataFlow::Node source, DataFlow::Node sink) {
  exists (DataFlow::Node operator, int n |
    StringConcatenation::taintStep(source, sink, operator, n) and
    hasSanitizingSubstring(StringConcatenation::getOperand(operator, [0..n-1])))
}

/**
 * Holds if the string value of `nd` prevents anything appended after it
 * from affecting the hostname of a URL.
 *
 * Specifically, this holds if the string contains any of the following:
 * - `?` (any suffix becomes part of query)
 * - `#` (any suffix becomes part of fragment)
 * - `/` or `\`, immediately prefixed by a character other than `:`, `/`, or `\` (any suffix becomes part of the path)
 *
 * In the latter case, the additional prefix check is necessary to avoid a `/` that could be interpreted as
 * the `//` separating the (optional) scheme from the hostname.
 */
private predicate hasHostnameSanitizingSubstring(DataFlow::Node nd) {
  nd.asExpr().getStringValue().regexpMatch(".*([?#]|[^?#:/\\\\][/\\\\]).*") 
  or
  hasHostnameSanitizingSubstring(StringConcatenation::getAnOperand(nd))
  or
  hasHostnameSanitizingSubstring(nd.getAPredecessor())
  or
  nd.isIncomplete(_)
}

/**
 * Holds if data that flows from `source` to `sink` cannot affect the
 * hostname or scheme of the resulting string when interpreted as a URL.
 *
 * This is considered as a sanitizing edge for the URL redirection queries.
 */
predicate hostnameSanitizingPrefixEdge(DataFlow::Node source, DataFlow::Node sink) {
  exists (DataFlow::Node operator, int n |
    StringConcatenation::taintStep(source, sink, operator, n) and
    hasSanitizingSubstring(StringConcatenation::getOperand(operator, [0..n-1])))
}