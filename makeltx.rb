require 'open3'

# -----------------------------------------------------------------------------
def latex_pass(input_file, pass, last = false)
  puts "PDFLaTeX pass [" << pass.to_s << "]..."
  options = "-interaction=nonstopmode"
  Open3.popen2("pdflatex", options, input_file) do |stdin, stdout, wait_thread|
    error = false
    stdout.each do |line|
      if error
        puts "    " << line
        error = false if /^l\.\d* / =~ line
        puts "---------------------" unless error
      else
        if /error|^\!/i =~ line
          error = true
        end
        if last
          if /undefined/i =~ line
            puts "    " << line
          end
        end
        if error
          puts "---------------------"
          puts "    " << line
        end
      end 
    end
    unless wait_thread.value.success?
      puts "[ERR] Error in pass [" << pass.to_s << "] of PDFLaTeX"
      puts "      Check <" << input_file << ".log> for more details"
      exit(1)
    end
  end
end

# -----------------------------------------------------------------------------
def clean_environment
  puts "Cleaning the environment..."
  command = "find . -type f"
  command = command << "|grep -v \"stuff\""
  command = command << "|egrep -v \"\.(rb|sh|tex|txt|bib|pdf|eps|png)$\""
  command = command << "|xargs rm -rf"
  Open3.popen2e(command) do |stdin, stdouterr, wait_thread|
    unless wait_thread.value.success?
      puts "Error cleaning the environment"
      exit(-2)
    end
  end
end

# -----------------------------------------------------------------------------
def bibtex_pass(input_file)
  puts "Generating the BibTex content..."
  Open3.popen2e("bibtex", input_file) do |stdin, stdouterr, wait_thread|
    stdouterr.each do |line|
      if /error/i =~ line
        puts line
      end
    end
    unless wait_thread.value.success?
      puts "Error generating the bibliography"
      exit(2)
    end
  end
end

# -----------------------------------------------------------------------------
def glossaries_pass(input_file)
  puts "Generating the glossaries..."
  Open3.popen2e("makeglossaries", input_file) do |stdin, stdouterr, wait_thread|
    stdouterr.each do |line|
      if /error/i =~ line
        puts line
      end
    end
    unless wait_thread.value.success?
      puts "Error generating the glossaries"
      exit(3)
    end
  end
end

# -----------------------------------------------------------------------------
# SCRIPT
if ARGV.size == 0
  puts "You have to specified AT LEAST one argument"
  exit(-1)
end

clean_environment
# Option to only clean the environment
unless /-c/i =~ ARGV[0]
  input_file = ARGV[0]
  puts "Processing <" << input_file << ">"
  latex_pass(input_file, 1)
  bibtex_pass(input_file)
  glossaries_pass(input_file)
  latex_pass(input_file, 2)
  latex_pass(input_file, 3, true)
end
puts "DONE"
