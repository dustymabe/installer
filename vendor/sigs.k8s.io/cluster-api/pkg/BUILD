load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["doc.go"],
    importmap = "installer/vendor/sigs.k8s.io/cluster-api/pkg",
    importpath = "sigs.k8s.io/cluster-api/pkg",
    visibility = ["//visibility:public"],
)
