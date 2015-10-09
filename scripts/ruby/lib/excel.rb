require "writeexcel"

def number_to_col(num)
  numeric = num % 26
  letter = chr(65 + numeric)
  num2 = (num / 26).to_i
  if num2 > 0
    return "#{number_to_col}#{letter}"
  else
    return $letter
  end
end

class ExcelWorkbook
  attr_reader :book
  def initialize(bookfile)
    @book = WriteExcel.new(File.join(config.export_dir, bookfile))
    @format_default = @book.add_format(:font => config.xls.default_font, :size => config.xls.default_font_size)
    @current_sheet = nil
    @current_row = 0
    @current_col = 0
  end
  # formats
  def format_header
    format_header = @book.add_format
    format_header.copy(@format_default)
    format_header.set_bold(1)
    return format_header
  end
  def format_detail
    format_detail = @book.add_format
    format_detail.copy(@format_default)
    format_detail.set_italic(1)
    return format_detail
  end
  def format_price
    format_price = @book.add_format
    format_price.copy(@format_default)
    format_price.set_num_format(0x07)
    return format_price
  end
  def col_letter(col)
    return (65 + col).chr
  end
  
  # Sheets
  def current_sheet
    if @current_sheet.nil? 
      @current_sheet = add_sheet
    end
    return @current_sheet
  end
  def work_on(sheet_name)
    @current_sheet = @book.sheets.select { |sheet| sheet.name == sheet_name }[0]
  end
  def add_sheet(name = nil)
    sheet = @book.add_worksheet(name)
    sheet.outline_settings(1,0,0)
    return sheet
  end 
  
  def append_to_row(row_content, col = 0, format = @default_format, collapsed = false)
    start_col = @current_col + col
    current_sheet.write_row(@current_row - 1, start_col, row_content, format)
    @current_col += col + row_content.size
    if collapsed
      current_sheet.set_column("#{col_letter(start_col + 1)}:#{col_letter(@current_col - 1)}", nil, nil, 1, 1)
    end
  end
  
  # Rows
  def add_row(row_content, col = 0, format = @format_default)
    current_sheet.write_row(@current_row, col, row_content, format)
    @current_row += 1
    @current_col = col + row_content.size
  end

  # Header
  def add_header(header, format = format_header)
    add_row(header, 0, format)
  end
  
  def add_detail_row(detail, col = 0, format = format_detail, collapsed = true)
    add_row(detail, col, format)
    if collapsed
      current_sheet.set_row(@current_row - 1, nil, nil, 1, 1)
    end
  end
  
  def save
    @book.close
  end
end
  