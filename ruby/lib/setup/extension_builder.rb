# BuildTool is a util class that is used to do some build tasks
class BuildTool
  def initialize(path)
    @v8eval_root = path
    @rb_dir = @v8eval_root + '/ruby'
    @rb_lib_dir = @rb_dir + '/lib'
    @rb_ext_dir = @rb_dir + '/ext'
    @rb_ext_v8eval_dir = @rb_ext_dir + '/v8eval'
  end

  def install_v8
    Dir.chdir @v8eval_root do
      system('./build.sh')
    end
  end

  def run_swig
    system('cp ' + @v8eval_root + '/src/v8eval.h ' + @rb_ext_v8eval_dir)
    system('cp ' + @v8eval_root + '/src/v8eval_ruby.h ' + @rb_ext_v8eval_dir)
    system('swig -c++ -ruby -autorename -outdir ' + @rb_ext_v8eval_dir +
      ' -o ' + @rb_ext_v8eval_dir + '/v8eval_wrap.cxx ' + @rb_ext_v8eval_dir +
      '/v8eval.i')
  end

  def build_ext
    Dir.chdir @rb_ext_v8eval_dir do
      system('ruby extconf.rb')
      system('make')
      system('cp -r ' + @rb_ext_v8eval_dir + ' ' + @rb_lib_dir)
    end
  end
end
