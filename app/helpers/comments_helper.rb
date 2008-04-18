module CommentsHelper
  def render_comment_body(body, position)
    if body =~ /^(#(\d+))\b/
      comment_index = $2.to_i
      if comment_index > 0 && comment_index < position
        body = body.sub($1, %@<a href="#comment_#{comment_index}">#{$1}</a>@)
      end
    end
    
    index = -1; 
    while index = body.index(/(@([\w\-\_]+))\b/, index+1)
      match = $1
      login = $2
      
      if User.find_by_login(login)
        replacement = body[index, match.length].sub(match, %@<a href="/users/#{login}">#{match}</a>@)
        body[index, match.length] = replacement
        index += replacement.length
      end
    end
    
    simple_format(sanitize(body))
  end
end
