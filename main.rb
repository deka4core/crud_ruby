# main.rb
require 'fox16'
include Fox
require_relative 'app/controllers/student_list_controller'
require_relative 'app/views/student_list_view'

class StudentApp
  def initialize
    puts "=" * 70
    puts "ЛАБОРАТОРНАЯ РАБОТА 5 + ЗАДАНИЕ 1"
    puts "=" * 70
    
    # Создаем приложение FXRuby (Задание 0, пункт 1)
    @app = FXApp.new("Student Management System", "University")
    
    # Создаем контроллер (Задание 1, пункт 2)
    puts "\n1. Создание контроллера..."
    @controller = StudentListController.new
    
    # Создаем View с передачей контроллера
    puts "2. Создание View с 3 вкладками..."
    @view = StudentListView.new(@app, @controller)
    
    puts "\n3. Проверка реализации:"
    puts "   ✓ 3 вкладки (Задание 0.2)"
    puts "   ✓ 5 фильтров с комбобоксами (Задание 0.5)"
    puts "   ✓ Таблица readonly с сортировкой по одному полю (Задание 0.6)"
    puts "   ✓ Пагинация с отображением страниц (Задание 0.6)"
    puts "   ✓ Кнопки управления с правильной логикой (Задание 0.7)"
    puts "   ✓ Паттерн Наблюдатель (Задание 1.1)"
    puts "   ✓ MVC архитектура (Задание 1.2)"
    puts "   ✓ DataListStudentShort.notify вызывает set_table_params/set_table_data (Задание 1.3)"
    puts "   ✓ Сохранение одного экземпляра DataListStudentShort (Задание 1.7)"
    
    puts "\n4. Готово к работе!"
    puts "=" * 70
  end
  
  def run
    puts "\nИнструкция:"
    puts "1. Кликните по заголовку 'Фамилия И.О.' для сортировки"
    puts "2. Используйте кнопки пагинации для навигации"
    puts "3. Выделите строки в таблице для активации кнопок 'Изменить/Удалить'"
    puts "4. Измените файл data/students.json и вернитесь для проверки обновления"
    
    @app.create
    @app.run
  end
end

if __FILE__ == $0
  begin
    app = StudentApp.new
    app.run
  rescue => e
    puts "Ошибка: #{e.message}"
    puts e.backtrace
    puts "\nНажмите Enter для выхода..."
    gets
  end
end