output "tasky_app_url" {
  description = "Public URL to access the Tasky. If the the value is not ready, a refresh should get the value."
  value = try(
    "http://${kubernetes_ingress_v1.app_ingress.status[0].load_balancer[0].ingress[0].hostname}",
    "not-ready-yet"
  )
}
