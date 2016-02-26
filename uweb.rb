#!/usr/bin/ruby -w

# {{{ !uweb
$usage = %Q{
= uweb(1)
:doctype: manpage

== NAME

`uweb` - Micro HTML based inverse literate programming tool.

== USAGE

`uweb [OPTIONS] [input.uw] > output.html`

`-h`, `--help`::

  Show this help message.

`-t template-directory`, `--template-dir template-directory`::

  Specify the directory containing the
  http://ruby-doc.org/stdlib/libdoc/erb/rdoc/ERB.html[ERB] template files to
  use. By default, `uweb will use the template files located next to the
  program itself.

`-o file`, `--output file`::

  The file to redirect the standard output to.

== INPUT

If no input file or the special `-` input file is given, then `uweb` will read
the standard input.

The input is a valid XHTML (or HTML if you are sloppy). This allows the input
file to be maintained by any X/HTML editor. To achieve this, `uweb` uses a
specific form of normal X/HTML elements for its commands. The commands are
detected using regular expressions, so they are a bit fussy about the format;
each command must appear in a line of its own and the order of attributes must
be exactly as described below. However, you can be free with white spaces, the
quote character you use and the case (upper or lower).

All the command tags are empty (have no text content), and `uweb will accept
all possible ways of expressing them - `<tag ...>`, `<tag ... />`, and `<tag
...></tag>`. Choose the form you prefer according to whether you are using
XHTML or HTML, and the tools you use (some are fussier than others).

=== `<link rel='source' href='relative path'>`

Scans the specified file for source chunks. These chunks can then be embedded
into the generated documentation. Note that no output is generated at this
point, and `uweb` will silently ignore source file lines that are not contained
in any chunk. It is good practice to surround the whole source file with a
top-level source chunk, to ensure all the code is properly documented.

A chunk is designated by surrounding comment lines. Different systems use
different ways to mark chunks (or foldable regions). Vim and Emacs recognize
regions using comments containing `{{{ name` and ending with `}}} [name]`.
These are typically surrounded by arbitrary non-alphanumeric comment
indicators such as `//`, `/* ... */`, `--` etc., which are ignored. In
contrast, Visual Studio doesn't use comments; instead it accepts the directives
`#region name` and `#endregion [name]`.

All these forms are recognized by `uweb`. Adding additional ones is a simple
matter of modifying the regular expression used to detect chunk comments. Note
that specifying the name after the end of the chunk is optional, but it if is
specified it must match the name given at the beginning of the chunk.

Lines can be excluded from being scanned for `uweb` comment lines by using the
special chunk name `!uweb`. In this case specifying the name after the end of
the chunk is mandatory.

If `uweb` encounters several chunks with the same name - in any of the scanned
source files - it expects them to contain exactly the same content (up to
indentation). This is the closest `uweb` can come to actually reusing the same
chunk.

All scan commands must appear before any chunk embedding commands, to allow
`uweb` to calculate all cross references. Hence `uweb` uses a `<link>` tag
which must appear in the <head> section of the X/HTML document, before any of
the `<body>` content.

=== `<a rel='include' name='relative path'>`

Includes the content of the specified file at this point, as if it was part of
the original input. This allows breaking up the input to several files for
easier maintenance.

=== `<a rel='chunk' name='chunk name'>`

Embed the specified named chunk at this point of the  generated documentation.
This command may only appear after the last <link rel='chunk'> was processed.
This should automatically be the case as <link> tags may only appear in the
<head> section. The chunk name must match one of the chunks detected when
scanning the linked source files.

If all the chunk's text lines are indented by some amount, then it is stripped
from the generated documentation lines. Nested chunks are converted to
hyperlinks; they need to be explicitly embedded elsewhere in the documentation.

== OUTPUT

The `uweb` output is an expanded valid XHTML (or HTML if you are sloppy)
documentation file. It is basically a copy of the input file, with `<link
rel='source'>` tags removed, and `<a rel='include'>` or `<a rel='chunk'>` tags
expanded to the appropriate content.

A common practice is to pipe the generated X/HTML through htmltoc, hypertoc or
a similar program to automatically generate a table of contents based on the
standard X/HTML header tags (`<h1>`, `<h2>`, ...).

The formatting of embedded chunks is determined by a two ERB files that are
located in the template directory (by default, next to the program itself).
Customizing or overriding these files allows to control the generated X/HTML
documentation.

=== `uweb.chunk`

This file contains an ERB template is used to convert the `<a rel='chunk'>` tag
into X/HTML documentation. Variables accessible to ERB are:

`name`::       Of the embedded chunk.

`refers_to`::  List of names of chunks included by this one.

`nested_in`::  List of names of chunks that include this one.

`lines`::      List of source lines of this chunk, without the stripped
               indentation and without the terminating line break characters.
               Nested chunks are already converted to hyperlinks.

`locations`::  List of the locations of this chunk in the scanned source files.
               Typically a chunk only appears in a single source file. However,
               some chunks are "reused" across several source files. Each entry
               is an object with the following fields:

`path`::       Of the source file this chunk appears in.

`first_line`:: Index of the first chunk source line in the file.

`last_line`::  Index of the last chunk source line in the file.

All indices are one-based. Apply the `String.idify` method to names when using
them in anchors.

=== `uweb.nest`

This template is used to collapse included chunks into hyperlinks to the
embedded nested chunk. Variables accessible to ERB are:

`indent`:: The additional indentation spaces stripped from the nested chunk,
          compared to the containing chunk.

`from`::   The name of the containing chunk.

`to`::     The name of the nested chunk.

Again, apply the `String.idify` method to names when using them in anchors.

== "Inverse" Literate Programming

Literate programming is a concept invented by Knuth, where the program is
written as a single source file called a "web" (this was 1981, before there
was an "Internet", never mind the "World Wide Web"). This "web" is "weaved"
to generate the human readable documentation and "tangled" to to generate
both program's machine readable source code. The "web" consists of a linear
presentation of the program (an article, a manual or even a book), containing
embedded code "chunks". Thus one needs to "tangle" the web, reordering and
combining the chunks into one or more source files that are then compiled as
usual. In contrast, "weaving" is mainly concerned with annotating the chunks
with cross-references, generating indices and a table of contents,
pretty-printing the code and other formatting issues.

The key insight of literate programming is overcoming the gap between the
best human presentation order, and the structural requirements imposed by the
programming language(s) used. The classical example at the time was allowing
to define a C function once in the narrative, then generating both a '.h'
declaration and a '.c' definition for it.

Literate programming has never become mainstream, especially with the
introduction of advanced IDEs with features such as intelligent
auto-completion and refactoring. However the notion of automatically
generating documentation from a source file (through "structured comments")
has gained popularity with JavaDoc and its innumerable clones for other
languages.

These popular tools, however, give up on the key insight of creating a linear
narrative for optimal presentation of the program. Instead their
documentation structure closely follows the physical code structure
(typically a loosely coupled collection of classes). This makes them ideally
suited for generating random-access library reference manuals. In contrast,
literate programming excels at describing "read input, run algorithm, write
output" programs.

The use of "inverse" literate programming allows generating a "classical"
literate programming style document from arbitrary source files, without
giving up on the use of IDEs, build systems etc. It even allows to retrofit
such documentation to any existing project with minimal disruption to the
existing source files.

The key idea (which `uweb` shamelessly lifts from http://progdoc.org/[ProgDoc]
is to invert the "tangle" step and incorporate it into the "weaving". That is,
instead of generating the source from chunks, extract the chunks from the
source files, and embed them into placeholders specified in the documentation.
This is how most code-related papers or articles are written in practice.

Note the term "inverse literate programming" was used by Heiko Kirschke to
describe what seems to be a "structured comments" tool for LISP. Also, the
term "reverse literate programming" was used by Markus Knasmuller in a
different meaning then the given above. ProgDoc implements "inverse" literate
programming but does not use a special term for it.

There are other tools implementing "inverse literate programming" in the sense
used here, for example https://github.com/orenbenkiki/codnar[Codnar] and
https://pythonhosted.org/antiweb[Antiweb].

=== Why `uweb`

There are many literate programming tools, each with its own set of trade-offs.
The `uweb` tool goals are, in descending order of importance:

==== Inverse literate programming

By providing an inverted form of literate programming (shamelessly lifted
from ProgDoc), `uweb` allows the source files to be maintained using your
favorite tools such as build systems or advanced syntax-highlighting
auto-completing refactoring wizard-infested IDEs. This also makes it possible
to retrofit literate programming documentation to existing projects.

==== Focus on HTML

The `uweb` input file is a valid X/HTML file (if you want it to be). This
allows any X/HTML editor to be used to maintain it, though you might have to
be careful about the formatting of the `uweb` commands.

If you want to focus on printed documentation, `uweb` is probably not the best
tool. It is of course possible to generate PDF (or even LaTeX) from the
X/HTML file, but you would get a much greater degree of control over the
output using many other literate programming tools.

==== Simplicity

The `uweb` tool uses a minimal set of commands and options. It is implemented
as a single Ruby file accompanied by two ERB template files, which you can
drop anywhere in your path. The whole script is about 400 lines of code
accompanied by roughly 300 lines of documentation.

==== Language independence

This means no code pretty printing, automatic indexing of identifiers, or any
similar language-specific advanced features. This trade-off is common to many
literate programming tools, though several allow for language-specific
plug-ins to implement some of these features.

==== Customization

By editing or overriding the template files bundled with `uweb`, it is easy to
customize the generated X/HTML documentation format. It is of course also
possible to customize the appearance of the result using CSS.

For more advanced features (e.g. indices, automatically numbered table of
contents, PDF generation), you can adapt the `uweb` templates to work with a
different input documentation format, such as DocBook (or even LaTeX).

In this case, however, you would probably also want to tweak the format of
the `uweb` commands as well, by modifying the regular expressions used for this
purpose (isolated from the rest of the code and clearly marked at the end of
the `uweb` script).

==== Portability

The `uweb` implementation is a pure Ruby file. It should work "out of the box"
on any Windows or UNIX platform. If you don't want to install Ruby, it should
be possible to convert it to a standalone executable using the `rubyscript2exe`
compiler.

== AUTHOR

mailto:uweb-oren@ben-kiki.org[Oren Ben-Kiki].

== VERSION

This is uweb version 0.3. For the latest version see
https://github.com/orenbenkiki/uweb[github].

== LICENSE

Copyright (C) 2008, 2016 Oren Ben-Kiki

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
uweb. If not, see http://www.gnu.org/licenses/.
}
# }}} !uweb

# {{{ Requirements
require 'set'
require 'getoptlong'
require 'erb'
begin
  require 'rubyscript2exe'
rescue LoadError
  # Not using rubyscript2exe.
end
# }}}

# {{{ Usage
# Since RDoc::usage is no more.
def usage
  print $usage
  exit(0)
end
# }}}

# {{{ Main program
def main
  parse_options
  load_templates
  $did_embed_chunks = false
  process_file($input)
  Chunk.verify_all_used if $warnings
end

def die(message)
  abort("#{$in_path}(#{$at_line_number}): #{message}")
end

def parse_options
  $template_dir = defined?(RUBYSCRIPT2EXE) ? RUBYSCRIPT2EXE.exedir \
                                           : File.dirname($0)
  $warnings = true
  GetoptLong.new([ '--help',          '-h', GetoptLong::NO_ARGUMENT ],
                 [ '--template-dir',  '-t', GetoptLong::REQUIRED_ARGUMENT ],
                 [ '--output-file',   '-o', GetoptLong::REQUIRED_ARGUMENT ],
                 [ '--no-warnings',   '-n', GetoptLong::NO_ARGUMENT ]) \
            .each do |option, argument|
    case option
      when '--help'
        usage
      when '--template-dir'
        $template_dir = argument
      when '--output-file'
        $stdout = File.open(argument, 'w')
      when '--no-warnings'
        $warnings = false
      else
        abort("Unknown option \"#{option}\"")
    end
  end
  case ARGV.length
  when 0
    $input = '-'
  when 1
    $input = ARGV[0]
  else
    usage
  end
end
# }}}

# {{{ Loading templates
def load_templates
  $chunk_template = load_template('uweb.chunk')
  $nest_template = load_template('uweb.nest')
end

def load_template(path)
  path = $template_dir + '/' + path
  abort("Missing template file \"#{path}\"") unless File.exist?(path)
  return ERB.new(IO.read(path))
end
# }}}

# {{{ Processing input
def process_file(file)
  each_file_line(file) do |line|
    case line
    when $source_pattern
      scan_source($source_pattern.extract(line))
    when $chunk_pattern
      embed_chunk($chunk_pattern.extract(line))
    when $include_pattern
      process_file($include_pattern.extract(line))
    else
      puts line
    end
  end
end

def each_file_line(path)
  $in_path ||= nil
  save_path = $in_path
  $in_path = path
  $at_line_number ||= nil
  save_line_number = $at_line_number
  $at_line_number = 0
  in_file = path == '-' ? $stdin : in_file = File.open($in_path, 'r')
  in_file.each_line do |line|
    line.chomp!
    $at_line_number += 1
    yield line
  end
  $in_path = save_path
  $at_line_number = save_line_number
end

# {{{ Scanning sources
$is_in_unscanned_chunk = false

def scan_source(path)
  die("<link rel='source'> after <a rel='chunk'>") if $did_embed_chunks
  instances = []
  each_file_line(path) do |line|
    if $end_pattern === line
      name = $end_pattern.extract(line)
      if not $is_in_unscanned_chunk
        die('End chunk outside any chunk') unless instances.size > 0
        die('End chunk "' + name \
          + '" does not match start chunk "' + instances.last.chunk.name + '"') \
          if name and name != instances.last.chunk.name
        instances.last.end_scan
        instances.pop
      elsif name == '!uweb'
        $is_in_unscanned_chunk = false
      end
      next
    end
    if !$is_in_unscanned_chunk and $begin_pattern === line
      name = $begin_pattern.extract(line)
      $is_in_unscanned_chunk = name == '!uweb'
      unless $is_in_unscanned_chunk
        die("Chunk #{name} contains itself") \
          if instances.any? { |instance| instance.chunk.name == name }
        parent = instances.last
        instance = Chunk.begin_scan(name)
        instances.push(instance)
        parent.add(instance) if parent
      end
      next
    end
    instances.last.add(line) if instances.last
  end
  die("Missing end of chunk \"#{instances.last.chunk.name}\"") \
    if instances.size > 0
end
# }}}
# }}}

# {{{ Embedding chunks
def embed_chunk(name)
  $did_embed_chunks = true
  chunk = Chunk.by_name(name)
  chunk.is_used = true
  # TRICKY: Captured by the binding.
  name = name = chunk.name
  refers_to = refers_to = chunk.refers_to.size == 0 ? nil : chunk.refers_to.entries.sort
  nested_in = nested_in = chunk.nested_in.size == 0 ? nil : chunk.nested_in.entries.sort
  locations = locations =
    chunk.instances.entries \
         .map { |instance| instance.location } \
         .sort
  lines = lines = \
    chunk.instances.entries[0].content \
          .map { |content| content.class == Instance ? nest_chunk(chunk, content) \
                                                     : content.escape_xhtml }
  $chunk_template.run(binding)
end

def nest_chunk(from_chunk, to_instance)
  # TRICKY: Captured by the binding.
  indent = indent = to_instance.indentation || ''
  from = from = from_chunk.name
  to = to = to_instance.chunk.name
  return $nest_template.result(binding).chomp
end
# }}}

# {{{ Tracking chunks
class Chunk
  def Chunk.begin_scan(name)
    @@chunk_by_name ||= {}
    return Instance.new(@@chunk_by_name[name] ||= Chunk.new(name))
  end

  def Chunk.by_name(name)
    @@chunk_by_name ||= {}
    chunk = @@chunk_by_name[name]
    die("Unknown chunk \"#{name}\"") unless chunk
    return chunk
  end

  def Chunk.verify_all_used
    exist_unused = false
    @@chunk_by_name.keys.sort.each do |name|
      next if @@chunk_by_name[name].is_used
      $stderr.puts("Chunk \"#{name}\" was not used")
      exist_unused = true
    end
    exit(1) if exist_unused
  end

  attr_reader :name, :instances, :refers_to, :nested_in
  attr_accessor :is_used

  def initialize(name)
    @name = name
    @instances = Set.new
    @refers_to = Set.new
    @nested_in = Set.new
    @is_used = false
  end

  def add(new_instance)
    old_instance = @instances.entries.last
    abort('Chunk "' + @name \
        + '" instance at file "' + new_instance.location.path \
        + '" line ' + new_instance.location.first_line.to_s \
        + ' has different content than instance at ' \
        + 'file "' + old_instance.location.path \
        + '" line ' + old_instance.location.first_line.to_s) \
      if old_instance and not old_instance.has_same_content?(new_instance)
    @instances.add(new_instance)
  end
end
# }}}

# {{{ Tracking locations
class Location
  attr_reader :path, :first_line, :last_line

  def initialize
    @path = $in_path
    @first_line = $at_line_number
  end

  def done
    @last_line = $at_line_number
  end

  def <=>(other)
    return @path == other.path ? @first_line <=> other.first_line \
                               : @path <=> other.path
  end
end
# }}}

# {{{ Tracking chunk instances
class Instance
  attr_reader :chunk, :location, :content, :indentation

  def initialize(chunk)
    @chunk = chunk
    @location = Location.new
    @content = []
    @indentation = nil
  end

  def add(content)
    @content.push(content)
    return unless content.class == Instance
    @chunk.refers_to.add(content.chunk.name)
    content.chunk.nested_in.add(@chunk.name)
  end

  def end_scan
    @indentation = @content.map { |c| c.indentation }.compact.min.clone || ''
    @location.done

    @content.each do |content|
      if content.class == Instance
        content.indentation.sub!(@indentation.clone, '') \
          if @indentation.size > 0
      else
        content.chomp!
        content.sub!(@indentation, '') if @indentation.size > 0
      end
    end
    @chunk.add(self)
  end

  def has_same_content?(other)
    return false unless @chunk == other.chunk
    return false unless @location.first_line - @location.last_line \
                     == other.location.first_line - other.location.last_line
    return false unless @content.size == other.content.size
    @content.each_index do |i|
      content = @content[i]
      other_content = other.content[i]
      return false unless content.class == other_content.class
      if content.class == Instance
        return false unless content.has_same_content?(other_content)
        return false unless (content.indentation == '') \
                         == (other_content.indentation == '')
      else
        return false unless content == other_content
      end
    end
    return true
  end
end
# }}}

# {{{ Detecting patterns
class Pattern
  def initialize(name, detect_regexp, extract_regexp)
    @name = name
    @detect_regexp = detect_regexp
    @extract_regexp = extract_regexp
  end

  def ===(line)
    return line =~ @detect_regexp
  end

  def extract(line)
    match = @extract_regexp.match(line)
    die('Invalid ' + @name) unless $is_in_unscanned_chunk or match
    return match && match[1]
  end
end
# }}}

# {{{ Monkey patching
class Array
  def map_with_index!
    each_with_index do |entry, index|
      self[index] = yield(entry, index)
    end
  end

  def map_with_index(&block)
    dup.map_with_index!(&block)
  end
end

class String
  def indentation
    return nil if self == ''
    return /^\s*/.match(self)[0]
  end

  def escape_xhtml
    return self.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;')
  end

  def idify
    return self.gsub(/\W+/, '-')
  end
end
# }}}

# Tweak the format of the uweb commands by modifying the following patterns:

# {{{ Input patterns
$source_pattern =
  Pattern.new("<link rel='source'> tag",
              / <
                \s* link
                \s .* rel
                \s* =
                \s* ['"]? source ['"]?
              /ix,
              / ^
                \s* <
                \s* link
                \s+ rel
                \s* =
                \s* ['"] source ['"]
                \s+ href
                \s* =
                \s* ['"] (.+) ['"]
                \s* \/?
                \s* >
                (?: \s* <
                    \s* link
                    \s* \/
                    \s* > )?
                \s* $
              /ix)

$include_pattern =
  Pattern.new("<a rel='include'> tag",
              / <
                \s* a
                \s .* rel
                \s* =
                \s* ['"] include ['"]
              /ix,
              / ^
                \s* <
                \s* a
                \s+ rel
                \s* =
                \s* ['"] include ['"]
                \s+ name
                \s* =
                \s* ['"] (.+) ['"]
                \s* \/?
                \s* >
                (?: \s* <
                    \s* a
                    \s* \/
                    \s* > )?
                \s* $
              /ix)

$chunk_pattern =
  Pattern.new("<a rel='chunk'> tag",
              / <
                \s* a
                \s .* rel
                \s* =
                \s* ['"] chunk ['"]
              /ix,
              / ^
                \s* <
                \s* a
                \s+ rel \s* =
                \s* ['"] chunk ['"]
                \s+ name
                \s* =
                \s* ['"] (.+) ['"]
                \s* \/?
                \s* >
                (?: \s* <
                    \s* a
                    \s* \/
                    \s* > )?
                \s* $
              /ix)
# }}}

# {{{ Source patterns
$begin_pattern =
  Pattern.new('Begin chunk',
              / (?: \{\{\{
                  | \# \s* region )
              /ix,
              / ^
                (?: \W* \{\{\{
                  | \s* \# \s* region )
                \s+ ( .+? )?
                (?: \s* \W+ )?
                \s* $
              /ix)

$end_pattern =
  Pattern.new('End chunk',
              / (?: \}\}\}
                  | \# \s* endregion )
              /ix,
              / ^
                (?: \W* \}\}\}
                  | \s* \# \s* region )
                (?: \s+ ( .+? ) )?
                (?: \s* \W+ )?
                \s* $
              /ix)
# }}}

main
