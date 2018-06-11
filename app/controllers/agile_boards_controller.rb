# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2018 RedmineUP
# http://www.redmineup.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

require 'sqlite3'

class AgileBoardsController < ApplicationController
  unloadable

  menu_item :agile
  
  #before_action :find_project, :except => [ :index, :list, :new, :create, :copy ] #find_project_by_project_id
  before_action :find_issue, :only => [:update, :issue_tooltip, :inline_comment]
  before_action :find_optional_project, :only => [:index, :create_issue]

  helper :issues
  helper :journals
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper
  helper :timelog
  include RedmineAgile::AgileHelper

#все нужные хелперы уже подключены



#
#генерация bpmn файла
#
  def bpmn
  
  
  #####################################################################################
  ###                        По хорошему в line_scheme в                             ##  
  ###  sourceref и tergetref нужно было указывать id element_scheme,а не element_id  ##
  #####################################################################################
  
  
retrieve_query
    if @query.valid?
   db = SQLite3::Database.open "/usr/share/redmine/plugins/redmine_agile/redminedb.sqlite3"
   #db.execute "INSERT INTO issues(tracker_id,project_id,subject,status_id,priority_id,author_id,lock_version,done_ratio,is_private) VALUES(2,1,'tyreeeee',1,2,1,0,0,'f')"
   
   #получаем количество объектов из element_scheme 

  #@issues = @query.issues(:limit => Setting.issues_export_limit.to_i)    
 


  #out_str = "-----" + @issues[0].project.id.to_s + "+++"
  
  #@query.each_hash do |row|
  #row.each_pair do |k, v|
  #  out_str += "column #{k} contains #{v}"
  #end
 #end

   out_str = ""    
    
    
   project_id = 1   ##научиться получать id проекта
   x = 212
   y = 87
   #project = context[:project]
   #project = Project.find(params[:project_id])
   #iddd = @project.project_id
   #target_projects = Project.where(:id => attributes['project_id']).to_a
   # project = context[:project]
   
   stm = db.prepare "SELECT COUNT(*) FROM element_scheme WHERE project_id = " + project_id.to_s + ";"
   elem_sch = stm.execute  
   elem_sch.each do |elem|
	  if elem == [0] #если таблица пустая
	    #создаем состояние начала
		id1 = "StartEvent_15"
   		db.execute "INSERT INTO element_scheme(element_id,project_id,type_element_id,x,y,width,height) VALUES('" + id1 + "'," + project_id.to_s + ",1," + x.to_s + "," + (y+18).to_s + ",36,36);"
		x_line1 = x + 36
        x = x + 36 + 20
		x_line2 = x
        #по задачам генерируем узлы и связи между ними(line_...) id,parent_id,subject
		sth = db.prepare "SELECT id,subject,parent_id FROM issues WHERE project_id = " + project_id.to_s + ";"
        tasks = sth.execute
		tasks.each do |row|
			db.execute "INSERT INTO type_element_scheme(name,width,height) VALUES('" + row[2].to_s + "',2,22);"

			if row[2].to_s == ""  ##если у задачи нет родителя
				##проверяем родитель ли она
				isparent = 0
				idparent = 0
				childx = x
				sthh = db.prepare "SELECT id,subject FROM issues WHERE parent_id = " + row[0].to_s + ";"
				tsksth = sthh.execute
				tsksth.each do |rowtsk| 
					db.execute "INSERT INTO type_element_scheme(name,width,height) VALUES('" + rowtsk.to_s + "',5,22);"
					##ессли у нее есть подзадачи, то делаем ее родительской и кладем в нее детей
					if isparent == 0
						id2 = "Task_" + row[0].to_s
						line_id = "ExclusiveGateway_" + x.to_s
						db.execute "INSERT INTO element_scheme(element_id,project_id,type_element_id,x,y,width,height,name,issues_id) VALUES('"+ id2 +"'," + project_id.to_s + ",10," + x.to_s + "," + y.to_s + ",100,80,'" + row[1].to_s + "'," + row[0].to_s + ");"
						idparent = db.last_insert_row_id
						db.execute "INSERT INTO line_scheme(sourceref,targetref,element_id,project_id) VALUES('" + id1 + "','" + id2 + "','" + line_id +"',"+ project_id.to_s + ");"
						id = db.last_insert_row_id
						db.execute "INSERT INTO line_option_scheme(x,y,line_scheme_id) VALUES(" + x_line1.to_s + "," + y.to_s + "," + id.to_s + ");"
						db.execute "INSERT INTO line_option_scheme(x,y,line_scheme_id) VALUES(" + x_line2.to_s + "," + y.to_s + "," + id.to_s + ");"
						id1 = id2
						x_line1 = x_line2 + 100
						x = x + 120
						x_line2 = x
					end
					# ##кладем ребенка в родителя
					isparent = 1
					fjjdfdf = rowtsk[0].to_s
					###rowtsk[0].to_s
					db.execute "INSERT INTO element_scheme(element_id,project_id,type_element_id,x,y,width,height,name,issues_id,parent_id) VALUES('Task_"+ fjjdfdf +"'," + project_id.to_s + ",9," + (childx + 5).to_s + "," + (y - 50).to_s + ",100,80,'" + rowtsk[1].to_s + "'," + rowtsk[0].to_s + "," + idparent.to_s + ");"
					childx = childx + 105					
				end
				if isparent == 0 ##если задача не родитель, то создаем обычную задачу
					id2 = "Task_" + row[0].to_s
					db.execute "INSERT INTO element_scheme(element_id,project_id,type_element_id,x,y,width,height,name,issues_id) VALUES('"+ id2 +"'," + project_id.to_s + ",9," + x.to_s + "," + y.to_s + ",100,80,'" + row[1].to_s + "'," + row[0].to_s + ");"
					line_id = "ExclusiveGateway_" + x.to_s
					db.execute "INSERT INTO line_scheme(sourceref,targetref,element_id,project_id) VALUES('" + id1 + "','" + id2 + "','" + line_id +"',"+ project_id.to_s + ");"
					id = db.last_insert_row_id
					db.execute "INSERT INTO line_option_scheme(x,y,line_scheme_id) VALUES(" + x_line1.to_s + "," + (y+40).to_s + "," + id.to_s + ");"
					db.execute "INSERT INTO line_option_scheme(x,y,line_scheme_id) VALUES(" + x_line2.to_s + "," + (y+40).to_s + "," + id.to_s + ");"
					id1 = id2
					x_line1 = x_line2 + 100
					x = x + 120
					x_line2 = x		
				end								
			end	
		end
		
		#создаем состояние окончания
		id2 = "EndEvent_1"
        db.execute "INSERT INTO element_scheme(element_id,project_id,type_element_id,x,y,width,height) VALUES('" + id2 + "'," + project_id.to_s + ",2," + x.to_s + "," + (y+18).to_s + ",36,36);"
		line_id = "ExclusiveGateway_" + x.to_s
		db.execute "INSERT INTO line_scheme(sourceref,targetref,element_id,project_id) VALUES('" + id1 + "','" + id2 + "','" + line_id +"',"+ project_id.to_s + ");"
		id = db.last_insert_row_id
		db.execute "INSERT INTO line_option_scheme(x,y,line_scheme_id) VALUES(" + x_line1.to_s + "," + (y+40).to_s + "," + id.to_s + ");"
		db.execute "INSERT INTO line_option_scheme(x,y,line_scheme_id) VALUES(" + x_line2.to_s + "," + (y+40).to_s + "," + id.to_s + ");"
	  
	  else
		#проверяем есть ли хотябы одно состояние начала
		##если его  нет, то создаем его и ни с кем не связываем
		stm_1 = db.prepare "SELECT COUNT(*) FROM element_scheme WHERE type_element_id = 1;"
		count = stm_1.execute  
		count.each do |cn|
			if cn == [0]
				id1 = "StartEvent_15"
				db.execute "INSERT INTO element_scheme(element_id,project_id,type_element_id,x,y,width,height) VALUES('" + id1 + "'," + project_id.to_s + ",1,170,45,36,36);"
			end
		end
		#проверяем есть ли хотябы одно состояние окончания
		##если его  нет, то создаем его и ни с кем не связываем
		stm_1 = db.prepare "SELECT COUNT(*) FROM element_scheme WHERE type_element_id = 2;"
		count = stm_1.execute  
		count.each do |cn|
			if cn == [0]
				id2 = "EndEvent_1"
				db.execute "INSERT INTO element_scheme(element_id,project_id,type_element_id,x,y,width,height) VALUES('" + id2 + "'," + project_id.to_s + ",2,210,45,36,36);"
			end
		end
		#проверяем есть ли узлы для задач, которые были удалены(идем по element_scheme и ищем соотвестсвующие им задачи)
		##если такая задача есть, то запоминаем ее id по ее element_id ищем все стрелки, запоминаем их id
		## удаляем из option_line_scheme все значения для id из line
		## удаляем все запомненные линии по их id
		## удаляем сам элемент
		#stm_1 = db.prepare "SELECT id,issues_id,element_id FROM element_scheme WHERE project_id = " + project_id.to_s + ";"
		#elmsch = stm_1.execute 
		#elmsch.each do |cn|
		# iss.each do |is|
			# sth_1 = db.prepare "SELECT COUNT(*) FROM issues WHERE id = " + is[0].to_s + ";"
			# count = sth_1.execute 
			# count.each do |cn|
				# if cn == [0] ##если мы не нашли задачу в issues по id
					# sth_2 = db.prepare "SELECT id FROM line_scheme WHERE sourceref = '" + is[2].to_s + "' or targetref = '" + is[2].to_s + "';"
					# lines2 = sth_2.execute
					# lines2.each do |ln2|
						# # del_1 = dp.prepare "DELETE FROM line_option_scheme WHERE line_scheme_id = " + ln2[0].to_s + ";"
						# # del_1.execute
						# # del_2 = dp.prepare "DELETE FROM line_scheme WHERE id = " + ln2[0].to_s + ";"
						# # del_2.execute
					# end
					# # del_3 = dp.prepare "DELETE FROM element_scheme WHERE id = " + el_sch[0].to_s + ";"
					# # del_3.execute
				# end
			# end
		# end
		#проверяем есть ли узел для задачи(идем по issues и ищем соотвестсвующие им узлы)
		##если узла нет, то создаем его
		stm_1 = db.prepare "SELECT id,subject,parent_id FROM issues WHERE project_id = " + project_id.to_s + ";"
		iss = stm_1.execute  
		x = 240
		y = 150
		newTasks = 0
		iss.each do |is|
			sth_1 = db.prepare "SELECT COUNT(*) FROM element_scheme WHERE issues_id = " + is[0].to_s + ";"
			count = sth_1.execute 
			count.each do |cn|			
				if cn == [0] ##если узел не найден, то создаем его
					newTasks = 1
					id2 = "Task_" + is[0].to_s
					db.execute "INSERT INTO element_scheme(element_id,project_id,type_element_id,x,y,width,height,name,issues_id) VALUES('"+ id2 +"'," + project_id.to_s + ",9," + x.to_s + "," + y.to_s + ",100,80,'" + is[1].to_s + "'," + is[0].to_s + ");"
					x += 100
				end
			end
		end
		##изменяем типы задач(родитель, ребенок)
		if newTasks == 1
			sth1 = db.prepare "SELECT id,issues_id,parent_id FROM element_scheme WHERE project_id = " + project_id.to_s + " and type_element_id = 9;"
			tsk = sth1.execute 
			tsk.each do |tas| ##идем по задачам, у которых нет детей 
			if tas[2].to_s == "" ##и нет родителей
				##задача родитель?
				sth2 = db.prepare "SELECT COUNT(*) FROM issues WHERE parent_id = " + tas[1].to_s + ";"
				count = sth2.execute 
				ispar = 0
				count.each do |cn|
					if cn != [0] ##задача - родитель
						ispar = 1
						sth_up = db.prepare "UPDATE element_scheme SET type_element_id = 10, width = 100, height = 80 WHERE id = " + tas[0].to_s + ";"
						upd = sth_up.execute
					end					
				end
				if ispar == 0 ##задача не родитель
					##задача ребенок?
					sth2 = db.prepare "SELECT parent_id FROM issues WHERE id = " + tas[1].to_s + ";"
					ts = sth2.execute
					ts.each do |t|
						if t[0].to_s != "" ##задача - ребенок
							sth_find = db.prepare "SELECT id,x,y FROM element_scheme WHERE issues_id = " + t[0].to_s + ";"
							fin = sth_find.execute
							xup = 0
							yup = 0
							pid = 0
							fin.each do |f|
								xup = f[1].to_s
								yup = f[2].to_s
								pid = f[0].to_s
							end
							sth_up = db.prepare "UPDATE element_scheme SET x = " + xup.to_s + ", y = " + yup.to_s + ", parent_id = " + pid.to_s + " WHERE id = " + tas[0].to_s + ";"
							upd = sth_up.execute
						end
					end
				end
			end#if
			end#цикл
		end		
	  end
   end

   
   #### создаем bpmn
   	# #заголовок
	
	out_str += "<?xml version=\"1.0\" encoding=\"UTF-8\"?><definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\" xmlns:bpmndi=\"http://www.omg.org/spec/BPMN/20100524/DI\" xmlns:omgdc=\"http://www.omg.org/spec/DD/20100524/DC\" xmlns:omgdi=\"http://www.omg.org/spec/DD/20100524/DI\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" targetNamespace=\"\" xsi:schemaLocation=\"http://www.omg.org/spec/BPMN/20100524/MODEL http://www.omg.org/spec/BPMN/2.0/20100501/BPMN20.xsd\">"
    out_str += "<collaboration id=\"Collaboration_1\">"
    out_str += "<participant id=\"Participant_1\" name=\"Scheme\" processRef=\"Process_1\" />"
    out_str += "</collaboration>"
    out_str += "<process id=\"Process_1\">"
	
    #идем по всем элементам из element_scheme и добавляем им стрелки(входящие, выходящие)
	sth = db.prepare "SELECT element_scheme.name,element_scheme.element_id, type_element_scheme.name, element_scheme.parent_id,element_scheme.id FROM element_scheme,type_element_scheme  WHERE type_element_scheme.id  = element_scheme.type_element_id and element_scheme.project_id = " + project_id.to_s  + ";"
	sch_el = sth.execute
	sch_el.each do |row|
	  if row[3].to_s == ""
	########после раскомментирования стрелок убрать / в конце
		count_lines = 0
		line_str = ""
		if row[0].to_s != ""
			out_str += "<" + row[2].to_s + " id=\"" + row[1].to_s + "\" name=\"" + row[0].to_s + "\""
		else
			out_str += "<" + row[2].to_s + " id=\"" + row[1].to_s + "\""
		end
		sth1 = db.prepare "SELECT element_id FROM line_scheme WHERE targetref = '" + row[1].to_s + "' and project_id = " + project_id.to_s  + ";"
		target = sth1.execute
		target.each do |line|
			line_str += "<incoming>" + line[0].to_s + "</incoming>"
			count_lines += 1
		end
		sth1 = db.prepare "SELECT element_id FROM line_scheme WHERE sourceref = '" + row[1].to_s + "' and project_id = " + project_id.to_s  + ";"
		source = sth1.execute
		source.each do |line|
			line_str += "<outgoing>" + line[0].to_s + "</outgoing>"
			count_lines += 1
		end
		sth3 = db.prepare "SELECT element_scheme.name,element_scheme.element_id, type_element_scheme.name FROM element_scheme,type_element_scheme  WHERE type_element_scheme.id  = element_scheme.type_element_id and element_scheme.parent_id = " + row[4].to_s  + ";"
		children = sth3.execute
		children.each do |child| ##если описываемый элемент имеет дочерние
			count_lines += 1
			count_lines2 = 0
			line_str2 = ""
			if child[0].to_s != ""
				line_str += "<" + child[2].to_s + " id=\"" + child[1].to_s + "\" name=\"" + child[0].to_s + "\""
			else
				line_str += "<" + child[2].to_s + " id=\"" + child[1].to_s + "\""
			end
			sth1 = db.prepare "SELECT element_id FROM line_scheme WHERE targetref = '" + child[1].to_s + "' and project_id = " + project_id.to_s  + ";"
			target = sth1.execute
			target.each do |line|
				line_str2 += "<incoming>" + line[0].to_s + "</incoming>"
				count_lines2 += 1
			end
			sth1 = db.prepare "SELECT element_id FROM line_scheme WHERE sourceref = '" + child[1].to_s + "' and project_id = " + project_id.to_s  + ";"
			source = sth1.execute
			source.each do |line|
				line_str2 += "<outgoing>" + line[0].to_s + "</outgoing>"
				count_lines2 += 1
			end
			if count_lines2 ==0
				line_str += "/>"
			else
				line_str +=">" + line_str2 + "</" + child[2].to_s + ">"
			end
		end
		if count_lines ==0
			out_str += "/>"
		else
			out_str +=">" + line_str + "</" + row[2].to_s + ">"
		end
	  end
	end

	#описываем стрелки
	sth1 = db.prepare "SELECT element_id,name,sourceref,targetref FROM line_scheme WHERE project_id = " + project_id.to_s  + ";"
	sch_line = sth1.execute
    sch_line.each do |line|
		if line[1] != ""
			out_str += "<sequenceFlow id=\"" + line[0].to_s + "\" name=\"" + line[1].to_s + "\" sourceRef=\"" + line[2].to_s + "\" targetRef=\"" + line[3].to_s + "\"/>"
		else
			out_str += "<sequenceFlow id=\"" + line[0].to_s + "\" sourceRef=\"" + line[2].to_s + "\" targetRef=\"" + line[3].to_s + "\"/>"
		end
	end
	out_str += "</process>"	
    ###описание характеристик элементов
	#шапка
	out_str += "<bpmndi:BPMNDiagram id=\"sid-74620812-92c4-44e5-949c-aa47393d3830\">"
    out_str += "<bpmndi:BPMNPlane id=\"sid-cdcae759-2af7-4a6d-bd02-53f3352a731d\" bpmnElement=\"Collaboration_1\">"
    out_str += "<bpmndi:BPMNShape id=\"Participant_1_di\" bpmnElement=\"Participant_1\">"
    out_str += "<omgdc:Bounds x=\"150\" y=\"20\" width=\"1100\" height=\"400\" />"
    out_str += "</bpmndi:BPMNShape>"
	#идем по всем элементам из element_scheme
	sth1 = db.prepare "SELECT element_id,x,y,width,height FROM element_scheme  WHERE project_id = " + project_id.to_s + ";"
	sch_el2 = sth1.execute
	sch_el2.each do |row|
		out_str += "<bpmndi:BPMNShape id=\"" + row[0].to_s + "_di\" bpmnElement=\"" + row[0].to_s + "\"><omgdc:Bounds x=\"" + row[1].to_s + "\" y=\"" + row[2].to_s + "\" width=\"" + row[3].to_s + "\" height=\"" + row[4].to_s + "\" /></bpmndi:BPMNShape>"        
	end
	# #идем по всем стрелкам из line_scheme
	sth = db.prepare "SELECT element_id,id FROM line_scheme WHERE project_id = " + project_id.to_s  + ";"
	sch_line2 = sth.execute
	sch_line2.each do |row|
		out_str += "<bpmndi:BPMNEdge id=\"" + row[0].to_s + "_di\" bpmnElement=\"" + row[0].to_s + "\">"
		sth1 = db.prepare "SELECT x,y FROM line_option_scheme WHERE line_scheme_id = " + row[1].to_s  + ";"
	    opt_line = sth1.execute
		opt_line.each do |option|
			out_str += "<omgdi:waypoint x=\"" + option[0].to_s + "\" y=\"" + option[1].to_s + "\" />"
		end
        out_str +="</bpmndi:BPMNEdge>"
	end
	out_str += "</bpmndi:BPMNPlane>"
    out_str += "<bpmndi:BPMNLabelStyle id=\"sid-e0502d32-f8d1-41cf-9c4a-cbb49fecf581\">"
    out_str += "<omgdc:Font name=\"Arial\" size=\"11\" isBold=\"false\" isItalic=\"false\" isUnderline=\"false\" isStrikeThrough=\"false\" />"
    out_str += "</bpmndi:BPMNLabelStyle>"
    out_str += "<bpmndi:BPMNLabelStyle id=\"sid-84cb49fd-2f7c-44fb-8950-83c3fa153d3b\">"
    out_str += "<omgdc:Font name=\"Arial\" size=\"12\" isBold=\"false\" isItalic=\"false\" isUnderline=\"false\" isStrikeThrough=\"false\" />"
    out_str += "</bpmndi:BPMNLabelStyle>"
    out_str += "</bpmndi:BPMNDiagram>"
	out_str += "</definitions>"
	
	db.execute "INSERT INTO type_element_scheme(name,width,height) VALUES('" + out_str + "',290,22);"

	#вывод в стиле php echo (антипаттерн)
    render html: out_str.html_safe

	else
      respond_to do |format|
        format.html { render :layout => !request.xhr? }
        format.any(:atom, :csv, :pdf) { head 422 }
        format.api { render_validation_errors(@query) }
      end
    end
	rescue ActiveRecord::RecordNotFound
    render_404

  end





  def index
    retrieve_agile_query
    if @query.valid?
      @issues = @query.issues
      @issue_board = @query.issue_board
      @board_columns = @query.board_statuses

      respond_to do |format|
        format.html { render :template => 'agile_boards/index', :layout => !request.xhr? }
        format.js
      end
    else
      respond_to do |format|
        format.html { render(:template => 'agile_boards/index', :layout => !request.xhr?) }
        format.js
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def update
  
     db = SQLite3::Database.open "C:\\redmine\\redminedb.sqlite3"

  	db.execute "INSERT INTO type_element_scheme(name,width,height) VALUES('UPDATE!!!!!',290,22);"

    (render_403; return false) unless @issue.editable?
    retrieve_agile_query_from_session
    old_status = @issue.status
    @issue.init_journal(User.current)
    @issue.safe_attributes = auto_assign_on_move? ? params[:issue].merge(:assigned_to_id => User.current.id) : params[:issue]
    checking_params = params.respond_to?(:to_unsafe_hash) ? params.to_unsafe_hash : params
    saved = checking_params['issue'] && checking_params['issue'].inject(true) do |total, attribute|
      if @issue.attributes.include?(attribute.first)
        total &&= @issue.attributes[attribute.first].to_i == attribute.last.to_i
      else
        total &&= true
      end
    end
    call_hook(:controller_agile_boards_update_before_save, { :params => params, :issue => @issue})
    @update = true
    if saved && @issue.save
      call_hook(:controller_agile_boards_update_after_save, { :params => params, :issue => @issue})
      AgileData.transaction do
        Issue.eager_load(:agile_data).find(params[:positions].keys).each do |issue|
          issue.agile_data.position = params[:positions][issue.id.to_s]['position']
          issue.agile_data.save
        end
      end if params[:positions]

      @inline_adding = params[:issue][:notes] || nil

      respond_to do |format|
        format.html { render(:partial => 'issue_card', :locals => {:issue => @issue}, :status => :ok, :layout => nil) }
      end
    else
      respond_to do |format|
        messages = @issue.errors.full_messages
        messages = [l(:text_agile_move_not_possible)] if messages.empty?
        format.html {
          render :json => messages, :status => :fail, :layout => nil
        }
      end
    end
  end

  def issue_tooltip
    render :partial => 'issue_tooltip'
  end

  def inline_comment
    render 'inline_comment', :layout => nil
  end

  private

  def auto_assign_on_move?
    RedmineAgile.auto_assign_on_move? && @issue.assigned_to.nil? &&
      !params[:issue].keys.include?('assigned_to_id') &&
      @issue.status_id != params[:issue]['status_id'].to_i
  end

#test graph gen
 






end
