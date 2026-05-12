variable "instances" {
  type = list(object({
    name         = string
    instanceType = string
    disk-size    = string
    models       = list(string)
  }))
  default = [
    {
      name         = "llm-node-1"
      instanceType = "g5.xlarge"
      disk-size    = "50"
      models       = ["llama3", "mistral"]
    },
    {
      name         = "llm-node-2"
      instanceType = "g5.2xlarge"
      disk-size    = "100"
      models       = ["codellama", "qwen"]
    }
  ]
}