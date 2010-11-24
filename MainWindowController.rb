# MainWindowController.rb
# sqlitebrowser
#
# Created by Ashley Towns on 17/11/10.
# Copyright 2010 Ashley Towns. All rights reserved.

require 'rubygems'
require 'sqlite3'	# Note: sqlite3-ruby *not* sqlite3

class MainWindowController < NSWindowController
	attr_accessor :tableView, :textInput, :infoLabel
	
	# WAKEEEE UPPPPPPPPPPP
	def awakeFromNib()
		@rows = @columns = []
		open_database
	end
	
	# Set the row, lookup what column where on via checking the 
	# index of the column via its identifier
	def tableView view, objectValueForTableColumn:column, row:index
		col_num = @columns.index(column.identifier) rescue 0
		@rows[index][col_num]
	end
	
	# Return how many rows we should have!
	def numberOfRowsInTableView view
		@rows.count 
	end
	
	# On enter or NSTextField loses focus trigger. Ruby regex support after ;;
	def textInputOnEnterPressed sender
		return if textInput.stringValue.strip == ""
		
		database_query = textInput.stringValue.split(';;')
		run_query database_query[0]
		if database_query.length > 1
			database_query[1..-1].each do |query|
				puts "Parsing query option: #{query}"
				left_right = query.split('=~')
				column_number = @columns.index left_right[0].strip
				regex = left_right[1].strip.match(/^\/(.*)\/$/)[1].strip
				puts "Found column number as #{column_number} searching for #{regex}"
				@rows = @rows.find_all{|row| row[column_number].to_s =~ /#{regex}/}  #puts "#{row[column_number]} =~ /#{regex}/"; 
				tableView.reloadData
				# Lets butcher the status reply
				time = infoLabel.stringValue.match(/And took (.*?) seconds to/)[1]
				infoLabel.setStringValue "Query returned #{@rows.length} results, And took #{time} seconds to run."
			end
		end
	end
	
	# Lets also grab drops and set that as our new database file
	def application theApplication, openFile:filename
		@database = filename
	end
	
	private
	# dup NSTableColumns, iterate and wipe. Iterate @columns and add to our table view
	def updateColumns
		tableView.tableColumns.dup.each{|col| tableView.removeTableColumn col }
		@columns.map{|col| NSTableColumn.alloc.initWithIdentifier col}.each{|col| col.headerCell.setStringValue col.identifier; tableView.addTableColumn col}
	end
	# Run a query! return the rows and columns, time how long it took and set as label
	def run_query query 
		if !@database.nil?
			begin_time = Time.now
			@columns, *@rows = SQLite3::Database.new(@database).execute2(query)
			updateColumns
			tableView.reloadData 
			infoLabel.setStringValue "Query returned #{@rows.length} results, And took #{Time.now - begin_time} seconds to run."
		else 
			infoLabel.setStringValue "You need to open a database first!"
		end
	end
	# Shows an open file dialog to set the database
	def open_database
		open_dialog = NSOpenPanel.openPanel 
		open_dialog.setCanChooseFiles true
		@database = open_dialog.filename if (open_dialog.runModalForDirectory nil, file: nil) == NSOKButton
	end
end
