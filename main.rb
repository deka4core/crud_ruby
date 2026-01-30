# main.rb
require 'fox16'
include Fox

require_relative 'app/views/main_window'

# Создаем и запускаем приложение
begin
  puts "Запуск приложения 'Управление студентами'..."
  app = FXApp.new("StudentManager", "FXRuby")
  window = MainWindow.new(app)
  app.create
  app.run
rescue => e
  puts "Ошибка запуска приложения: #{e.message}"
  puts e.backtrace
  puts "Нажмите Enter для выхода..."
  gets
end