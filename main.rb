# main.rb
require 'fox16'
require_relative 'app/views/student_list_view'
require_relative 'app/controllers/student_list_controller'

include Fox

class StudentApp
  def initialize
    @app = FXApp.new("Student Management", "StudentApp")
    
    # Создаем View
    @view = StudentListView.new(@app)
    
    # Создаем контроллер с ссылкой на View
    @controller = StudentListController.new(@view)
    
    # Связываем View с контроллером
    @view.controller = @controller
    
    puts "Приложение инициализировано"
  end
  
  def run
    @app.create
    @app.run
  end
end

# Запуск приложения
if __FILE__ == $0
  begin
    puts "Запуск приложения..."
    puts "Текущая директория: #{Dir.pwd}"
    app = StudentApp.new
    app.run
  rescue => e
    puts "Ошибка при запуске приложения: #{e.message}"
    puts e.backtrace
  end
end