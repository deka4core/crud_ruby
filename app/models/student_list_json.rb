require 'json'
require_relative 'student'
require_relative 'student_short'
require_relative 'data_list_student_short'

# Класс для управления списком студентов, хранящимся в JSON файле.
#
# Класс предоставляет полный CRUD функционал
# для работы со студентами, а также методы для сортировки, пагинации
# и экспорта данных в формат, пригодный для отображения.
#
# @author dekacore
# @since 1.0.0
# @version 1.0.0
class StudentsListJSON
  # @return [String] путь к файлу JSON, с которым работает данный экземпляр
  attr_reader :file_path
  
  # Инициализирует новый экземпляр StudentsListJSON.
  #
  # При указании пути к файлу автоматически загружает данные из него,
  # если файл существует. Если файл не существует, создается пустой список.
  #
  # @param [String, nil] file_path путь к JSON файлу со списком студентов.
  #   Если не указан, список будет пустым.
  #
  # @raise [JSON::ParserError] если JSON файл содержит синтаксические ошибки
  def initialize(file_path = nil)
    @students = []
    @file_path = file_path
    load_data if file_path && File.exist?(file_path)
  end

  # Загружает данные студентов из JSON файла.
  #
  # Метод парсит JSON файл и создает объекты {Student} на основе полученных данных.
  # Если файл не существует или пуст, список студентов остается пустым.
  #
  # @note Метод вызывается автоматически при создании экземпляра с указанием file_path.
  #
  # @return [void]
  # @raise [JSON::ParserError] если JSON файл содержит синтаксические ошибки
  # @see #save_data
  def load_data
    return unless File.exist?(@file_path)
    
    json_data = File.read(@file_path)
    data = JSON.parse(json_data, symbolize_names: true)
    
    @students = data.map do |student_data|
      Student.new(
        id: student_data[:id],
        first_name: student_data[:first_name],
        last_name: student_data[:last_name],
        patronymic: student_data[:patronymic],
        git: student_data[:git],
        phone: student_data[:phone],
        telegram: student_data[:telegram],
        email: student_data[:email]
      )
    end
  end

  # Сохраняет данные студентов в JSON файл.
  #
  # Метод преобразует все объекты {Student} в хэши и сохраняет их в JSON формате
  # в файл, указанный при создании экземпляра.
  #
  # @note Для работы метода должен быть установлен {#file_path}.
  #
  # @return [void]
  #
  # @see #load_data
  def save_data
    return unless @file_path
    
    students_data = @students.map do |student|
      {
        id: student.id,
        first_name: student.first_name,
        last_name: student.last_name,
        patronymic: student.patronymic,
        git: student.git,
        phone: student.instance_variable_get(:@phone),
        telegram: student.instance_variable_get(:@telegram),
        email: student.instance_variable_get(:@email)
      }
    end
    
    File.write(@file_path, JSON.pretty_generate(students_data))
  end

  # Находит студента по его идентификатору.
  #
  # @param [Integer] id идентификатор студента для поиска.
  #
  # @return [Student, nil] найденный объект {Student} или nil, если студент
  #   с таким ID не найден.
  def get_student_by_id(id)
    @students.find { |student| student.id == id }
  end

  # Возвращает подмножество студентов в формате, пригодном для отображения.
  #
  # Метод возвращает k студентов, начиная с позиции
  # (n-1)*k. Результат конвертируется в {StudentShort} объекты и упаковывается
  # в {DataListStudentShort} для удобного отображения в табличном виде.
  #
  # @param [Integer] k количество студентов на "странице".
  # @param [Integer] n номер "страницы" (начинается с 1).
  # @param [DataList, nil] existing_data_list существующий объект DataList
  #   для повторного использования (опционально). Если передан, метод обновит
  #   его данные вместо создания нового объекта.
  #
  # @return [DataListStudentShort] объект для отображения списка студентов.
  #
  # @note Если запрошенный диапазон выходит за пределы списка,
  #   возвращаются только существующие студенты.
  def get_k_n_student_short_list(k, n, existing_data_list = nil)
    start_index = (n - 1) * k
    end_index = start_index + k - 1
    
    selected_students = @students[start_index..end_index] || []
    
    student_shorts = selected_students.map do |student|
      StudentShort.from_student(student)
    end
    
    if existing_data_list && existing_data_list.is_a?(DataList)
      existing_data_list.data = student_shorts
      existing_data_list
    else
      DataListStudentShort.new(student_shorts)
    end
  end

  # Сортирует список студентов по фамилии с инициалами.
  #
  # Сортировка выполняется в алфавитном порядке без учета регистра.
  # Метод изменяет порядок элементов в исходном списке.
  #
  # @return [void]
  #
  # @see Student#last_name_initials
  def sort_by_full_name
    @students.sort_by! do |student|
      student.last_name_initials.downcase
    end
  end

  # Добавляет нового студента в список.
  #
  # Метод автоматически генерирует новый уникальный ID для студента
  # (на 1 больше максимального существующего ID) и создает новый объект
  # {Student} с этим ID.
  #
  # @param [Student] student объект студента для добавления.
  #
  # @return [Student] новый объект студента с присвоенным ID.
  #
  # @note Исходный объект student не изменяется. Создается новый объект
  #   с присвоенным ID.
  # @note Если список пуст, новый студент получает ID = 1.
  def add_student(student)
    # Генерируем новый ID
    new_id = @students.empty? ? 1 : @students.map(&:id).max + 1
    
    # Создаем нового студента с новым ID
    student_with_id = Student.new(
      first_name: student.first_name,
      last_name: student.last_name,
      patronymic: student.patronymic,
      id: new_id,
      git: student.git,
      phone: student.instance_variable_get(:@phone),
      telegram: student.instance_variable_get(:@telegram),
      email: student.instance_variable_get(:@email)
    )
    
    @students << student_with_id
    student_with_id
  end

  # Заменяет студента с указанным ID новым объектом студента.
  #
  # @param [Integer] id идентификатор студента для замены.
  # @param [Student] new_student новый объект студента.
  #
  # @return [Boolean] true, если замена выполнена успешно;
  #   false, если студент с указанным ID не найден.
  #
  # @note ID студента сохраняется. Новый объект создается с оригинальным ID.
  def replace_student_by_id(id, new_student)
    index = @students.find_index { |student| student.id == id }
    return false unless index
    
    @students[index] = Student.new(
      first_name: new_student.first_name,
      last_name: new_student.last_name,
      patronymic: new_student.patronymic,
      id: id,
      git: new_student.git,
      phone: new_student.instance_variable_get(:@phone),
      telegram: new_student.instance_variable_get(:@telegram),
      email: new_student.instance_variable_get(:@email)
    )
    true
  end

  # Удаляет студента с указанным ID из списка.
  #
  # @param [Integer] id идентификатор студента для удаления.
  #
  # @return [Boolean] true, если студент был найден и удален;
  #   false, если студент с указанным ID не найден.
  #
  # @note ID удаленного студента освобождается и больше не используется.
  def delete_student_by_id(id)
    initial_size = @students.size
    @students.reject! { |student| student.id == id }
    initial_size != @students.size
  end

  # Возвращает количество студентов в списке.
  #
  # @return [Integer] текущее количество студентов.
  def get_student_short_count
    @students.size
  end

  # Возвращает копию списка всех студентов.
  #
  # Метод возвращает массив, содержащий всех студентов в текущем порядке.
  # Возвращается копия массива, поэтому изменения в возвращенном массиве
  # не влияют на внутреннее состояние объекта.
  #
  # @return [Array<Student>] массив всех студентов.
  def all_students
    @students.dup
  end

  private

  # @return [Array<Student>] внутренний массив студентов.
  # @private
  attr_accessor :students
end