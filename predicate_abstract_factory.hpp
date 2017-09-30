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

enum class attribute
{
	file,
	directory,
	hidden,
	readonly
};

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
	attribute attr;
	inner_state(){}
	inner_state(const inner_state& copy) : 
			size(copy.size),
			str(copy.str),
			attr(copy.attr)
	{
	}
	inner_state& operator=(const inner_state& from)
	{
		size=from.size;
		str=from.str;
		attr=from.attr;
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
		virtual ~predicate()
		{}
		predicate(const inner_state& _st):st(_st){}
		predicate(){}
		void set_inner_state(const inner_state& _st)
		{
			st=_st;
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
					virtual ~Not()
					{
						if(prev)
							delete prev;
					}
				private:
					const predicate* prev=nullptr;
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
					virtual ~And()
					{
						if(prev_left)
							delete prev_left;
						if(prev_right)
							delete prev_right;
					}
				private:
					const predicate* prev_left=nullptr;
					const predicate* prev_right=nullptr;
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
					virtual ~Or()
					{
						if(prev_left)
							delete prev_left;
						if(prev_right)
							delete prev_right;
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
void predicate_driver(const std::string&, const predicate*);
