/// Unwraps a value the codegen pipeline expects to be present at an analyzer or
/// registry boundary — element names, resolved annotations, previously-registered
/// [ClassInfo], nullable AST fields — where the analyzer API types it nullable but
/// the surrounding logic guarantees it is set.
///
/// Throwing a descriptive [StateError] (instead of a bare `!` null-check crash)
/// keeps the "must exist" invariant explicit and gives a useful message if a
/// future change ever violates it.
T requirePresent<T extends Object>(T? value, String what) {
  if (value case final v?) return v;
  throw StateError(
      'basalt_codegen: expected $what to be present, but it was null');
}
