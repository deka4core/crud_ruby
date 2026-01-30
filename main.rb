# main.rb
require 'fox16'
require_relative 'app/views/main_window'

begin
  puts "Запуск приложения..."
  app = FXApp.new("StudentSystem", "Univer")
  main_window = MainWindow.new(app)

  app.create
  
  puts "Приложение запущено"
  app.run
  
rescue => e
  puts "Ошибка запуска приложения: #{e.message}"
  puts e.backtrace
  puts "Нажмите Enter для выхода..."
  gets
end