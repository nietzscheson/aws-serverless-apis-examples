data "archive_file" "handler" {  
  type = "zip"  
  source_file = "${path.module}/../src/handler.py" 
  output_path = "${local.name}.zip"
}