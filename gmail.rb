#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-
#
# Copyright (c) 2010 iwagaki@users.sourceforge.net
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'tlsmail'
require 'time'

class Gmail
  attr_accessor :subject
  attr_accessor :message

  def initialize(gmail_user, gmail_password, gmail_address)
    @gmail_user = gmail_user
    @gmail_password = gmail_password
    @gmail_address = gmail_address
  end

  def send_html(to_address)
    @to_address = to_address
    content = get_plain_header()
    content << get_html_header()
    content << "\n"
    content << @message
    send(content)
  end

  def send_plain(to_address)
    @to_address = to_address
    content = get_plain_header()
    content << "\n"
    content << @message
    send(content)
  end

  private
  def send(content)
    Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
    Net::SMTP.start('smtp.gmail.com', 587, 'gmail.com', @gmail_user, @gmail_password, :login) { |smtp|
      smtp.send_message(content, @gmail_address, @to_address)
    }
  end

  def get_plain_header()
    content = <<"EOB"
From: #{@gmail_address}
To: #{@to_address}
Subject: #{@subject}
Date: #{Time.now.rfc2822}
EOB
    return content
  end

  def get_html_header()
    content = <<"EOB"
Content-Type: multipart/related; boundary="boundary-here--"

--boundary-here--
Content-Type: text/html; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit
EOB
    return content
  end
end
#Content-Type: text/html; charset="UTF-8"
#Content-Type: text/html; charset="Shift_JIS"


# if __FILE__ == $0
#   Gmail.send("Gmail_account_name", "Gmail_password", "From_address", "To_address", "Subject", "Body")
# end
