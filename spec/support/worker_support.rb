module WorkerSupport
  def work_until_finished
    schedulers = []
    5.times do
      schedulers << Process.fork do
        begin
          Resque.redis.client.reconnect
          Resque::Scheduler.run
        rescue => e
          puts e.inspect
          puts e.backtrace.join("\n")
        end
      end
    end
    workers = []
    5.times do
      workers << Process.fork do
        begin
          Resque.redis.client.reconnect
          Resque::Worker.new(:test).work(1)
        rescue => e
          puts e.inspect
          puts e.backtrace.join("\n")
        end
      end
    end
  
    any_running = true
    while(any_running)
      any_running = false
      Resque.redis.keys("meta*").each do |key|
        meta = Resque::Plugins::Meta.get_meta(key.split(":").last)
        if meta.finished?
          # puts "finished #{meta['job_class']}"
        else
          any_running = true
          # puts "still running #{meta['job_class']}"
        end
      end
      sleep(0.5)
    end

    # sleep 15

    # debugger
    # 1

    #
    schedulers.each do |scheduler|
      Process.kill("HUP", scheduler)
    end
    workers.each do |worker|
      Process.kill("HUP", worker)
    end
    #
    # sleep 1

    # while true
    #   begin
    #     current_q = Resque.peek(:test, 0, 100)
    #     pp current_q
    #     puts times_empty
    #     if current_q.empty?
    #       times_empty += 1
    #     else
    #       times_empty = 0
    #     end
    #     if times_empty > 5
    #       schedulers.each do |scheduler|
    #         Process.kill("HUP", scheduler)
    #       end
    #       workers.each do |worker|
    #         Process.kill("HUP", worker)
    #       end
    #       sleep 1
    #       return
    #     else
    #       sleep 1
    #     end
    #   rescue => e
    #     puts e.inspect
    #   end
    # end



    # Resque::Scheduler.load_schedule!
    #
    # @worker.work(0)
    # while(Resque.delayed_queue_schedule_size > 0)
    #   Resque::Scheduler.handle_delayed_items
    #   sleep 1
    #   pp Resque.peek(:test, 0, 100)
    #   @worker.work(0)
    #   sleep 1
    #   pp Resque.peek(:test, 0, 100)
    # end
    #
    # puts "DONE"
    #
    # debugger
    # 1

    # sleep 2

    # work = Proc.new do
    #   # pp Resque.peek(:test, 0, 100)
    #   @worker.work(0)
    #   # pp Resque.peek(:test, 0, 100)
    #   q_size = Resque.delayed_queue_schedule_size || 0
    #   # puts q_size.inspect
    #   if(q_size > 0)
    #     Resque::Scheduler.handle_delayed_items
    #     work.call
    #   end
    # end
    # work.call
    # sleep 1
    # debugger
    # 1

    # SystemTimer.timeout(10) do
    #   until @hit_the_instance
    #     sleep(0.5)
    #   end
    # end
  end
end