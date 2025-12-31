#![feature(rustc_private)]
#![warn(unused_extern_crates)]

// Single dylint_library! declaration for multiple lints
dylint_linting::dylint_library!();

extern crate rustc_hir;
extern crate rustc_lint;
extern crate rustc_session;
extern crate rustc_span;

use rustc_hir::{Expr, ExprKind, LetStmt, Mutability, PatKind};
use rustc_lint::{LateContext, LateLintPass, LintContext};
use rustc_session::{declare_lint, declare_lint_pass};
use rustc_span::Span;

// =============================================================================
// NO_MUT_BINDINGS - Deny mutable variables
// =============================================================================

declare_lint! {
    /// Denies mutable bindings (`let mut x = ...`).
    ///
    /// Gleam has no mutable variables. All values are immutable.
    pub NO_MUT_BINDINGS,
    Deny,
    "Gleam style: no mutable bindings (let mut)"
}

declare_lint_pass!(NoMutBindings => [NO_MUT_BINDINGS]);

impl<'tcx> LateLintPass<'tcx> for NoMutBindings {
    fn check_local(&mut self, cx: &LateContext<'tcx>, local: &'tcx LetStmt<'tcx>) {
        if let PatKind::Binding(binding_annot, _, ident, _) = local.pat.kind {
            if binding_annot.1 == Mutability::Mut {
                cx.span_lint(
                    NO_MUT_BINDINGS,
                    local.pat.span,
                    |diag| {
                        diag.primary_message(format!(
                            "Gleam style: mutable binding `mut {}` is not allowed. \
                             Use immutable bindings and return new values instead.",
                            ident.name
                        ));
                    },
                );
            }
        }
    }
}

// =============================================================================
// NO_LOOPS - Deny imperative loops (for, while, loop)
// =============================================================================

declare_lint! {
    /// Denies imperative loops (`for`, `while`, `loop`).
    ///
    /// Gleam has no loops. Use iterators and recursion instead.
    pub NO_LOOPS,
    Deny,
    "Gleam style: no imperative loops (for/while/loop)"
}

declare_lint_pass!(NoLoops => [NO_LOOPS]);

impl<'tcx> LateLintPass<'tcx> for NoLoops {
    fn check_expr(&mut self, cx: &LateContext<'tcx>, expr: &'tcx Expr<'tcx>) {
        if let ExprKind::Loop(_, _, source, _) = expr.kind {
            let loop_type = match source {
                rustc_hir::LoopSource::Loop => "loop",
                rustc_hir::LoopSource::While => "while",
                rustc_hir::LoopSource::ForLoop => "for",
            };
            cx.span_lint(
                NO_LOOPS,
                expr.span,
                |diag| {
                    diag.primary_message(format!(
                        "Gleam style: `{}` loops are not allowed. \
                         Use iterator methods (.map(), .filter(), .fold()) or recursion instead.",
                        loop_type
                    ));
                },
            );
        }
    }
}

// =============================================================================
// NO_MUT_REFS - Deny mutable references (&mut)
// =============================================================================

declare_lint! {
    /// Denies mutable references (`&mut T`).
    ///
    /// Gleam has no mutable references. Return new values instead.
    pub NO_MUT_REFS,
    Deny,
    "Gleam style: no mutable references (&mut)"
}

declare_lint_pass!(NoMutRefs => [NO_MUT_REFS]);

impl<'tcx> LateLintPass<'tcx> for NoMutRefs {
    fn check_expr(&mut self, cx: &LateContext<'tcx>, expr: &'tcx Expr<'tcx>) {
        if let ExprKind::AddrOf(_, Mutability::Mut, _) = expr.kind {
            cx.span_lint(
                NO_MUT_REFS,
                expr.span,
                |diag| {
                    diag.primary_message(
                        "Gleam style: mutable references `&mut` are not allowed. \
                         Return new values instead of mutating in place."
                    );
                },
            );
        }
    }

    fn check_fn(
        &mut self,
        cx: &LateContext<'tcx>,
        _: rustc_hir::intravisit::FnKind<'tcx>,
        decl: &'tcx rustc_hir::FnDecl<'tcx>,
        _: &'tcx rustc_hir::Body<'tcx>,
        _span: Span,
        _: rustc_hir::def_id::LocalDefId,
    ) {
        for input in decl.inputs {
            if let rustc_hir::TyKind::Ref(_, ref_ty) = input.kind {
                if ref_ty.mutbl == Mutability::Mut {
                    cx.span_lint(
                        NO_MUT_REFS,
                        input.span,
                        |diag| {
                            diag.primary_message(
                                "Gleam style: function parameters with `&mut` are not allowed. \
                                 Take ownership and return a new value instead."
                            );
                        },
                    );
                }
            }
        }
    }
}

// =============================================================================
// Registration
// =============================================================================

#[unsafe(no_mangle)]
pub fn register_lints(_sess: &rustc_session::Session, lint_store: &mut rustc_lint::LintStore) {
    lint_store.register_lints(&[NO_MUT_BINDINGS, NO_LOOPS, NO_MUT_REFS]);
    lint_store.register_late_pass(|_| Box::new(NoMutBindings));
    lint_store.register_late_pass(|_| Box::new(NoLoops));
    lint_store.register_late_pass(|_| Box::new(NoMutRefs));
}

#[test]
fn ui() {
    dylint_testing::ui_test(env!("CARGO_PKG_NAME"), "ui");
}
