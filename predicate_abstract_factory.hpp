/**
 *  Description:
 *  Author: Igor Diakonov
 *  Date: 26.09.17 21:07:41
 */
#pragma once
#include <map>
#include <string>
#include <sstream>
#include <stdexcept>
#include <boost/filesystem.hpp>

namespace bf=boost::filesystem;

struct state
{
	bf::path file;
	state(){}
	state(const state& copy) : file(copy.file)
	{
	}
	state& operator=(const state& from)
	{
		file=from.file;
		return *this;
	}
};

struct inner_state
{
	uint32_t size;
	std::string str;
	inner_state(){}
	inner_state(const inner_state& copy) : 
			size(copy.size),
			str(copy.str)
	{
	}
	inner_state& operator=(const inner_state& from)
	{
		size=from.size;
		str=from.str;
		return *this;
	}
};

class predicate
{
	private:
		inner_state st;
	protected:
		inner_state get_inner_state() const
		{
			return st;
		}
	public:
		virtual bool operator()(const state&) const =0;
		virtual predicate* clone() const =0;
		predicate(const inner_state& st):st(st){}
		predicate(){}
		void set_inner_state(const inner_state& inner_st)
		{
			st=st;
		}
		
		predicate* operator! () const
		{
			class Not : public predicate
			{
				public:
					Not(const Not* x) : prev(x->get_prev())
					{
						set_inner_state(x->get_inner_state());
					}
					Not(const predicate* x) : prev(x->clone())
					{
						set_inner_state(x->get_inner_state());
					}
					virtual bool operator()(const state& s) const override 
					{
						return !((*prev)(s));
					}
					virtual predicate* clone() const override 
					{
						return new Not(this);
					}
					const predicate* get_prev() const
					{
						return prev;
					}
				private:
					const predicate* prev;
			};
			return new Not(this);
		}

		predicate* operator&& (predicate* b) const
		{
			class And : public predicate
			{
				public:
					And(const predicate* left, const predicate* right): 
						prev_left(left->clone()), 
						prev_right(right->clone())
						{
						}
					And(const And* x) :
						prev_left(x->get_prev_left()),
						prev_right(x->get_prev_right())
						{
						}
					virtual bool operator()(const state& s) const override 
					{
						return ((*prev_left)(s)) && ((*prev_right)(s));
					}
					virtual predicate* clone() const override 
					{
						return new And(this);
					}
					const predicate* get_prev_left() const
					{
						return prev_left;
					}
					const predicate* get_prev_right() const
					{
						return prev_right;
					}
				private:
					const predicate* prev_left;
					const predicate* prev_right;
			};
			return new And(this, b);
		}

		predicate* operator|| (predicate* b) const
		{
			class Or : public predicate
			{
				public:
					Or(const predicate* left, const predicate* right): 
						prev_left(left->clone()), 
						prev_right(right->clone())
						{
						}
					Or(const Or* x) :
						prev_left(x->get_prev_left()),
						prev_right(x->get_prev_right())
						{
						}
					virtual bool operator()(const state& s) const override 
					{
						return ((*prev_left)(s)) || ((*prev_right)(s));
					}
					virtual predicate* clone() const override 
					{
						return new Or(this);
					}
					const predicate* get_prev_left() const
					{
						return prev_left;
					}
					const predicate* get_prev_right() const
					{
						return prev_right;
					}
				private:
					const predicate* prev_left;
					const predicate* prev_right;
			};
			return new Or(this, b);
		}

};

class predicate_abstract_factory
{
	private:
		std::map<std::string, predicate*> functions;
	public:
		predicate_abstract_factory()
		{	
		};
		class NOT_FOUND{};
		class ALREADY_EXISTS{};
		void register_function(const std::string& name, predicate* p)
		{
			if(functions.find(name)==functions.end())
				functions[name]=p;
			else
				throw predicate_abstract_factory::ALREADY_EXISTS();
		}
		void unregister_function(const std::string& name)
		{
			if(functions.find(name)!=functions.end())
				functions.erase(name);
			else
				throw predicate_abstract_factory::NOT_FOUND();
		}
		predicate* get_function(const std::string& name)
		{
			return functions[name]->clone();
		}
		std::stringstream list_functions()
		{
			std::stringstream s;
			for(const auto& name: functions)
			{
				s.str(name.first);
				s.str("\n");
			}
			return s;
		}
};

void initialize_factory(predicate_abstract_factory& fact);
