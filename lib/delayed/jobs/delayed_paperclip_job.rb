require 'ruby-debug'
Debugger.start
Debugger.settings[:autoeval] = true


class DelayedPaperclipJob < Struct.new(:instance_klass, :instance_id, :attachment_name)
  def perform
    process_job do
      instance.send(attachment_name).reprocess!
      instance.send("#{attachment_name}_processed!")
    end
  end


  def error(job, exc)
    instance.send "#{attachment_name}_post_process_error", job, exc if instance.respond_to? "#{attachment_name}_post_process_error"
  end

  def after(job)
    instance.send "after_#{attachment_name}_post_process", job if instance.respond_to? "after_#{attachment_name}_post_process"
  end

  def success(job)
    instance.send "success_#{attachment_name}_post_process", job if instance.respond_to? "success_#{attachment_name}_post_process"
  end

  def before(job)
    instance.send "before_#{attachment_name}_post_process", job if instance.respond_to? "before_#{attachment_name}_post_process"
  end

  private
  def instance
    @instance ||= instance_klass.constantize.find(instance_id)
  end
  
  def process_job
    instance.send(attachment_name).job_is_processing = true
    yield
    instance.send(attachment_name).job_is_processing = false    
  end
end