# data.tf
resource "aws_dynamodb_table_item" "book_1" {
  table_name = aws_dynamodb_table.book_inventory.name
  hash_key   = aws_dynamodb_table.book_inventory.hash_key
  range_key  = aws_dynamodb_table.book_inventory.range_key

  item = <<ITEM
{
  "ISBN": {"S": "9780132350884"},
  "Genre": {"S": "Software Engineering"},
  "Title": {"S": "Clean Code"},
  "Author": {"S": "Robert C. Martin"},
  "Price": {"N": "34.99"},
  "Stock": {"N": "12"}
}
ITEM
}

resource "aws_dynamodb_table_item" "book_2" {
  table_name = aws_dynamodb_table.book_inventory.name
  hash_key   = aws_dynamodb_table.book_inventory.hash_key
  range_key  = aws_dynamodb_table.book_inventory.range_key

  item = <<ITEM
{
  "ISBN": {"S": "9780439708180"},
  "Genre": {"S": "Fantasy"},
  "Title": {"S": "Harry Potter and the Sorcerer's Stone"},
  "Author": {"S": "J.K. Rowling"},
  "Price": {"N": "19.99"},
  "Stock": {"N": "25"}
}
ITEM
}

resource "aws_dynamodb_table_item" "book_3" {
  table_name = aws_dynamodb_table.book_inventory.name
  hash_key   = aws_dynamodb_table.book_inventory.hash_key
  range_key  = aws_dynamodb_table.book_inventory.range_key

  item = <<ITEM
{
  "ISBN": {"S": "9780451524935"},
  "Genre": {"S": "Dystopian"},
  "Title": {"S": "1984"},
  "Author": {"S": "George Orwell"},
  "Price": {"N": "15.50"},
  "Stock": {"N": "40"}
}
ITEM
}

resource "aws_dynamodb_table_item" "book_4" {
  table_name = aws_dynamodb_table.book_inventory.name
  hash_key   = aws_dynamodb_table.book_inventory.hash_key
  range_key  = aws_dynamodb_table.book_inventory.range_key

  item = <<ITEM
{
  "ISBN": {"S": "9780316769488"},
  "Genre": {"S": "Fiction"},
  "Title": {"S": "The Catcher in the Rye"},
  "Author": {"S": "J.D. Salinger"},
  "Price": {"N": "12.99"},
  "Stock": {"N": "18"}
}
ITEM
}

resource "aws_dynamodb_table_item" "book_5" {
  table_name = aws_dynamodb_table.book_inventory.name
  hash_key   = aws_dynamodb_table.book_inventory.hash_key
  range_key  = aws_dynamodb_table.book_inventory.range_key

  item = <<ITEM
{
  "ISBN": {"S": "9781400079988"},
  "Genre": {"S": "Historical Fiction"},
  "Title": {"S": "The Kite Runner"},
  "Author": {"S": "Khaled Hosseini"},
  "Price": {"N": "16.75"},
  "Stock": {"N": "9"}
}
ITEM
}