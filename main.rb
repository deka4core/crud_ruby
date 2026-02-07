require 'fox16'
include Fox
require_relative 'app/controllers/student_list_controller'
require_relative 'app/views/student_list_view'

class StudentApp
  def initialize
    @app = FXApp.new("Student Management System", "University")
    @controller = StudentListController.new
    @view = StudentListView.new(@app, @controller)
  end
  
  def run
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
    gets
  end
end