require '/Users/Albert/Repos/Scripts/ruby/lib/utilities.rb'
require '/Users/Albert/Repos/Scripts/ruby/nimzo/nimzo.rb'

# Accepts arrays of paths/files, determines what content they require and then creates those files.
class NimzoFileMaker

    TYPE_CONTROLLER = 'controller'
    TYPE_JS = 'js'
    TYPE_JS_MIN = 'js-min'
    TYPE_LESS = 'less'
    TYPE_TEST = 'test'
    TYPE_VIEW = 'view'

    # @param type
    # @param paths
    # @param files
    # @param space
    def initialize(type = '', paths = Array.new, files = Array.new, space = '')

        @type = type
        @paths = paths
        @files = files
        @space = space

        @namespace = @type.capitalize

        # Make sure the particular controller type is valid.
        # This error cannot be reached through incorrect user input.
        unless inArray(%w(app modal overlay system widget), @type)
            puts("\x1B[33m#{@type}\x1B[0m is not a valid controller type. There is an error in your bash script, not your input.")
            exit
        end

        self.createPaths
        self.createFiles

    end

    # @param paths
    def createPaths(paths = @paths)
        unless paths.kind_of?(Array)
            exitScript("Expected Array, you passed (#{paths.class})")
        end
        unless paths.empty?
            paths.each { |path| self.createPath(path) }
        end
    end

    # @param path
    def createPath(path)
        unless path.kind_of?(String)
            exitScript("Expected String, you passed (#{path.class})")
        end
        unless File.directory?(path)
            FileUtils::mkdir_p(path)
            puts " \x1B[32mCreated:\x1B[0m \x1B[90m#{path.sub("#{$PATH_TO_PHP}/", '')[0..-1]}\x1B[0m"
        end
    end

    # @param files
    def createFiles(files = @files)
        unless files.kind_of?(Array)
            exitScript("Expected Array, you passed (#{files.class})")
        end
        unless files.empty?
            files.each { |file| self.createFile(file) }
        end
    end

    # @param file
    def createFile(file)
        unless file.kind_of?(String)
            exitScript("Expected String, you passed (#{file.class})")
        end
        if File.file?(file)
            exitScript("File already exists: #{file}")
        else
            self.createPath(File.dirname(file))
            File::new(file, 'w')
            # Add file to Git.
            system ("cd #{$PATH_TO_REPO}")
            system ("git add #{file.sub("#{$PATH_TO_REPO}", '')[1..-1]}")
            populateFile(file)
            puts " \x1B[32mCreated:\x1B[0m \x1B[0m#{file.sub("#{$PATH_TO_REPO}/", '')[0..-1]}\x1B[0m"
        end
    end

    # Figures out what kind of file this is (controller, .js, test, etc) and then goes to create it.
    def populateFile(file)
        if file.include? "#{$PATH_TO_PHP}#{@type}/controllers/"
            self.createFileController(file, File.dirname(file).sub("#{$PATH_TO_PHP}#{@type}/controllers/", ''))
            return
        end
        if file.include? "#{$PATH_TO_MIN}#{@type}"
            self.createFileJsMin(file, File.dirname(file).sub("#{$PATH_TO_MIN}#{@type}", ''))
            return
        end
        if file.include? "#{$PATH_TO_DEV}#{@type}"
            if file.reverse[0..2].reverse == '.js'
                self.createFileJs(file, File.dirname(file).sub("#{$PATH_TO_DEV}#{@type}", ''))
                return
            else
                self.createFileLess(file, File.dirname(file).sub("#{$PATH_TO_DEV}#{@type}", ''))
                return
            end
        end
        if file.include? "#{$PATH_TO_TESTS}#{@type}/controllers/"
            self.createFileTest(file, File.dirname(file).sub("#{$PATH_TO_TESTS}#{@type}/controllers/", ''))
            return
        end
        if file.include? "#{$PATH_TO_PHP}#{@type}/views/"
            self.createFileView(file, File.dirname(file).sub("#{$PATH_TO_PHP}#{@type}/views/", ''))
            return
        end
        exitScript('Couldn\'t determine file type.')
    end

    # Creates the Controller.
    # @param file
    def createFileController(file, route)
        className = ''
        route.split('/').each { |routeParameter|
            routeParameter[0] = routeParameter.upcase[0..0]
            className = "#{className}#{routeParameter}"
        }
        File.open(file, 'w') { |file|
            file.puts '<?php'
            file.puts ''
            file.puts "namespace #{@namespace};"
            file.puts ''
            file.puts '/**'
            file.puts " * @package #{@namespace}"
            file.puts ' */'
            file.puts "class #{className} extends #{@namespace}Base implements #{@namespace}Interface"
            file.puts '{'
            file.puts '    /**'
            file.puts '     * @return void'
            file.puts '     */'
            file.puts '    public static function init()'
            file.puts '    {'
            file.puts '    }'
            file.write '}'
        }
    end

    # Creates the .js (MIN) file.
    # @param file
    def createFileJsMin(file, route)
        jsObjectName = ''
        route.split('/').each { |routeParameter|
            jsObjectName = "#{jsObjectName}#{routeParameter.capitalize}"
        }
        File.open(file, 'w') { |file|
            file.write "var #{@namespace}_#{jsObjectName}={}"
        }
    end

    # Creates the .js (DEV) file.
    # @param file
    def createFileJs(file, route)
        jsObjectName = ''
        route.split('/').each { |routeParameter|
            jsObjectName = "#{jsObjectName}#{routeParameter.capitalize}"
        }
        File.open(file, 'w') { |file|
            file.puts "var #{@namespace}_#{jsObjectName} = {"
            file.write '}'
        }
    end

    # Creates the .less file.
    # @param file
    def createFileLess(file, route)
    end

    # Creates the PHPUnit Test.
    # @param file
    def createFileTest(file, route)
        className = ''
        group = @namespace
        route.split('/').each { |routeParameter|
            className = "#{className}#{routeParameter.capitalize}"
        }
        className = "#{className}Test"
        File.open(file, 'w') { |file|
            file.puts '<?php'
            file.puts ''
            file.puts "namespace #{@namespace};"
            file.puts ''
            file.puts 'use PHPUnit_Framework_TestCase;'
            file.puts ''
            file.puts '/**'
            file.puts " * @group #{group}"
            route.split('/').each { |routeParameter|
                group = "#{group}/#{routeParameter.capitalize}"
                file.puts " * @group #{group}"
            }
            file.puts " * @package #{@namespace}"
            file.puts ' */'
            file.puts "class #{className} extends PHPUnit_Framework_TestCase"
            file.puts '{'
            file.puts '    /**'
            file.puts '     * @return void'
            file.puts '     */'
            file.puts '    public function setUp()'
            file.puts '    {'
            file.puts '    }'
            file.puts ''
            file.puts '    /**'
            file.puts '     * @return void'
            file.puts '     */'
            file.puts '    public function tearDown()'
            file.puts '    {'
            file.puts '    }'
            file.puts ''
            file.puts '    /**'
            file.puts '     * @return void'
            file.puts '     */'
            file.puts '    public function testSomething()'
            file.puts '    {'
            file.puts '        $this->assertTrue(true);'
            file.puts '    }'
            file.write '}'
        }
    end

    # Creates the View.
    # @param file
    def createFileView(file, route)
    end
end