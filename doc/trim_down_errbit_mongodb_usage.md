```
errs = Err.limit(10000).sort_by { |o| o.notices.count }.reverse

errs.take(10).each do |err|
  puts "Destroying: #{err.problem.message}"
  err.problem.destroy
end
```


def delete_all_by_keyword!(string)
  problems = Problem.all.select { |p| p.message.to_s.include?(string) }

  problems.each do |problem|
    begin
      problem.destroy!
      puts "Problem #{problem.err} has been deleted"
    rescue => e
      puts e.message
    end
  end

  notices = Notice.all.select { |p| p.message.to_s.include?(string) }
  notices.each do |notice|
    begin
      if notice.err.present?
        notice.err.destroy!
        puts "Err #{notice.err} has been deleted"
      else
        notice.destroy!
        puts "Notice #{notice} has been deleted"
      end
    rescue => e
      puts e.message
    end
  end
  nil
end

Problem.all.select { |p| p.notices.count.zero? }.each(&:destroy!) ; nil
